# mall-customer 与 smart-cs-multi-agent Python 版逐步对照

> 对照日期：2026-11-06。依据当前工作区代码静态检查；未启动模型、Redis、MySQL 或进行端到端测试。
>
> 对照范围：`mall-dev/mall-customer` 对 `smart-cs-multi-agent-main/python-impl`。参考项目的 Java、Go 实现不作为代码差异基线；商城接入部分另看 `mall-dev/mall-server` 与 `mall-dev/mall-portal`。

## 标记说明

- **[新增]** 当前项目新增、参考 Python 版没有的行为。
- **[改造]** 两边都有，但当前项目改变了实现方式。
- **[沿用]** 主要逻辑与参考版相同，不能算当前项目的改进。
- **[未接入]** 文件或接口存在，但不在主聊天图的执行链上。
- **[风险]** 从代码可直接推导出的错误边界；具体发生频率需要运行数据验证。

## 先看完整调用顺序

```text
商城页面 CustomerModal
  → mall-server CustomerController.chat（取登录用户）
  → MessageServiceImpl.chat（检查会话归属，保存用户消息）
  → mall-customer /api/chat（创建本轮 HumanMessage，以 session_id 作 thread_id）
  → trim_history（裁剪到 20 条消息）
  → supervisor_route（直接用 LLM 选一个 Agent 名称）
  → knowledge_rag / ticket_handler / chitchat / compliance_check 四选一
  → compliance_check（前三个分支都经过；直达此节点时没有草稿可审）
  → synthesize（保留草稿、撤回草稿并给兜底话术，或生成普通兜底）
  → /api/chat 在整轮图完成后按 4 字分块发送 SSE
  → mall-server 拼接回复并保存 AI 消息
  → 页面逐块展示
```

参考版只有 Python 服务链：`/api/chat → supervisor_route → knowledge_rag/ticket_handler/compliance_check → synthesize → JSON`。其 Redis 消息列表和图状态是分开的。

## 逐步差异与代码标记

### 01. 用户入口、身份和会话

**参考版：[沿用的服务入口]** FastAPI 的 `ChatRequest` 接受 `message`、可由请求传入的 `user_id` 和 `session_id`，直接处理 `/api/chat`。参见 [参考 API](../../../smart-cs-multi-agent-main/python-impl/api/main.py#L83)。

**当前版：[新增商城入口]** 页面调用 Java 的 `/portal/customer/chat`；Java 从 Sa-Token 取得登录用户，再确认 `cs_session.user_id` 与登录用户一致，随后将该用户 ID 和会话 ID 传给 Python。页面的会话创建、历史切换和消息显示也在商城内。参见 [前端发送](../../mall-portal/src/components/CustomerModal.vue#L209)、[Java Controller](../../mall-server/src/main/java/com/supermarket/controller/portal/CustomerController.java#L60)、[Java 会话校验与转发](../../mall-server/src/main/java/com/supermarket/service/impl/MessageServiceImpl.java#L45)。

**区别与边界：** 商城页面调用链有登录和会话归属校验；Python 的 `/api/chat` 本身仍信任请求里的 `user_id/session_id`，并未独立校验。部署时应保证 Python 接口只接受可信内部调用，或增加服务间身份校验。Python 的 `/api/history/{session_id}` 和 `/api/tools/call` 也是独立暴露的接口，不能把 Java 侧的校验自动视作它们的校验。参见 [当前 API](../../mall-customer/api/main.py#L89)、[历史接口](../../mall-customer/api/main.py#L162)、[工具调用接口](../../mall-customer/api/main.py#L177)。

### 02. 会话记录写到哪里

**参考版：[沿用]** 请求前后调用 `short_term_memory.add_message()`，把用户与客服文本写入 Redis list；`/api/history` 读该列表。参见 [参考 API](../../../smart-cs-multi-agent-main/python-impl/api/main.py#L104)、[参考 Redis 列表](../../../smart-cs-multi-agent-main/python-impl/memory/short_term.py#L57)。

**当前版：[改造]** Java 在调用 Python 前保存用户消息，在 SSE 正常完成且收到非空回复后保存客服消息；会话、消息分别存在 MySQL 的 `cs_session`、`cs_message`。Python 的 `/api/history` 读 LangGraph checkpoint，不读 MySQL。参见 [消息保存时机](../../mall-server/src/main/java/com/supermarket/service/impl/MessageServiceImpl.java#L59)、[表结构](../../db/schema.sql#L1)、[Python 历史读取](../../mall-customer/memory/short_term_memory.py#L50)。

**区别与边界：** 当前有两个不同用途的数据源：MySQL 保存面向用户的历史，checkpoint 保存模型下一轮的上下文。它们没有统一事务；Python 图成功而 Java SSE 中途断开时，两侧历史可能不同。需要用 `message_id/request_id` 关联一次对话，并定义失败、重试和补偿策略。

### 03. 模型创建

**参考版：[沿用]** Supervisor 默认硬编码 `ChatOpenAI(model="gpt-4o")`。参见 [参考 Supervisor](../../../smart-cs-multi-agent-main/python-impl/agents/supervisor.py#L166)。

**当前版：[改造]** 从 `MODEL_NAME`、`OPENAI_API_KEY`、`OPENAI_BASE_URL` 环境变量构建 `ChatOpenAI`，`temperature=0`。参见 [当前 Supervisor](../../mall-customer/agents/supervisor.py#L198)。

**作用：** 模型和代理地址可以按环境切换。代码没有验证模型名为空、模型输出格式能力或超时配置，因此“可配置”不代表每个模型都能稳定返回所要求的 Agent 名称和 JSON。

### 04. 图的初始状态与多轮恢复

**参考版：[沿用但未贯通]** 每轮传入新的 `HumanMessage` 和多个重置字段；`thread_id=session_id` 虽然存在，但图编译默认使用进程内 `MemorySaver`。另有 Redis 历史列表，却没有把该列表读回本轮图输入。参见 [参考 API 初始状态](../../../smart-cs-multi-agent-main/python-impl/api/main.py#L106)、[参考图编译](../../../smart-cs-multi-agent-main/python-impl/agents/supervisor.py#L203)。

**当前版：[改造]** 启动时初始化 `AsyncRedisSaver`，传入 `graph.compile(checkpointer=...)`；本轮仅提供新消息和业务字段，同一 `thread_id` 可以恢复上轮 `messages`。Redis 不可用时降级进程内 `MemorySaver`。参见 [checkpointer 初始化](../../mall-customer/memory/short_term_memory.py#L28)、[图接线](../../mall-customer/api/main.py#L47)、[本轮输入](../../mall-customer/api/main.py#L113)。

**作用与边界：** 这是多轮能力的核心改进。但 Redis 降级后跨重启、跨进程的上下文不再一致，当前只有打印日志，没有把降级状态通过健康检查或指标明确暴露。当前每轮仍重新输入 `intent=""`、`compliance_passed=True` 等字段，历史对话主要依靠 `messages`，而非这些字段保持。

### 05. 历史窗口

**参考版：[沿用]** Redis list 使用 `ltrim` 限制条数；这个限制作用在单独的历史列表上。参见 [参考短期记忆](../../../smart-cs-multi-agent-main/python-impl/memory/short_term.py#L57)。

**当前版：[新增图节点]** `trim_history` 在路由前用 `RemoveMessage` 删除超过 20 条的最旧消息；`messages` 使用 `add_messages` reducer。参见 [状态和窗口](../../mall-customer/agents/supervisor.py#L32)、[入口节点](../../mall-customer/agents/supervisor.py#L224)。

**作用与边界：** 图内可见上下文有了上限。固定“20 条”可能删除仍有效的订单号、工单号与用户目标；重要业务实体应单独放结构化状态或持久化业务数据，不应只靠最近聊天文本保存。

### 06. Supervisor 路由

**参考版：[沿用]** 给 LLM 全部图内消息，要求只返回 `knowledge_rag`、`ticket_handler`、`compliance_checker` 中的一个；不符合列表时默认知识检索。参见 [参考路由](../../../smart-cs-multi-agent-main/python-impl/agents/supervisor.py#L69)。

**当前版：[改造]** 提示词增加商城咨询、业务办理、闲聊的分工，允许返回 `chitchat`；不符合列表仍默认知识检索。工作记忆只记录 `last_intent`。参见 [当前路由](../../mall-customer/agents/supervisor.py#L63)、[当前路由执行](../../mall-customer/agents/supervisor.py#L94)。

**作用与边界：** “你好”可避开 RAG。但输出只有一个 Agent 名称，没有细分业务意图、对象 ID、置信度或缺失信息；“退款政策是什么”与“帮我申请退款”是否分开，仍依赖模型一次文本分类。多任务消息也只能走单一路由。

### 07. IntentRouterAgent 的实际位置

**参考版与当前版：[未接入]** 两边都定义并实例化了 `IntentRouterAgent`，它能给出一级/二级意图、置信度和实体；但两边都没有将其注册为图节点，也没有调用 `classify/process`。当前文件内容仅有空行差异，金融意图规则仍是参考版规则。参见 [当前 IntentRouter](../../mall-customer/agents/intent_router.py#L64)、[只实例化未接入](../../mall-customer/agents/supervisor.py#L208)、[图节点列表](../../mall-customer/agents/supervisor.py#L216)。

**准确表述：** 当前系统“有意图识别 Agent 文件”，但主对话的意图识别是 Supervisor 的 LLM 路由。不能把 `IntentResult.confidence/entities` 描述为已投入使用。

### 08. 闲聊分支

**参考版：[无此分支]** 非工单、非合规消息通常落到知识问答。

**当前版：[新增]** `ChitchatAgent` 直接调用 LLM，提示不编造商品价格、订单状态和优惠承诺；图把 `chitchat` 接入合规检查。参见 [闲聊 Agent](../../mall-customer/agents/chitchat.py#L32)、[图分支](../../mall-customer/agents/supervisor.py#L220)。

**作用与边界：** 避免无意义的向量查询。若一句话同时含寒暄和业务问题，单标签路由可能只处理一半；可在结构化路由中让业务意图优先，闲聊只决定回复语气。

### 09. 知识问答：查询改写

**两版：[沿用]** `KnowledgeRAGAgent.process()` 只取 `messages[-1].content`，然后 LLM 改写查询。当前项目没有改动此主逻辑。参见 [当前 RAG](../../mall-customer/agents/knowledge_rag.py#L118)、[参考 RAG](../../../smart-cs-multi-agent-main/python-impl/agents/knowledge_rag.py#L118)。

**风险：** “那这个多少钱”“刚才那件能退吗”这类指代问题，即使 checkpoint 恢复了历史，RAG 仍只用本轮文本检索，可能失去商品或订单对象。需要先从历史/结构化状态补全问题，再改写检索词。

### 10. 知识问答：索引、召回、重排、生成

**两版：[沿用]** FAISS 的向量由文本 SHA-256 种子生成随机数，不是语义 embedding；检索取前 5，LLM 根据截断的文档摘要返回索引，再取前 3，最后由 LLM 基于文档生成答案。当前项目只是把 `long_term.py` 重命名为 `long_term_memory.py`。参见 [向量生成](../../mall-customer/memory/long_term_memory.py#L66)、[向量查询](../../mall-customer/memory/long_term_memory.py#L107)、[重排](../../mall-customer/agents/knowledge_rag.py#L64)、[生成](../../mall-customer/agents/knowledge_rag.py#L96)。

**风险：** 哈希随机向量没有语义相似性，`top_k` 结果没有相关性阈值；重排解析只检验索引小于文档数，没有排除负数、重复项或超出 `top_k` 的结果。RAG 生成提示虽然要求标来源，但没有程序验证引用是否对应真实片段。**这里是当前回答精度的首要技术瓶颈。**

### 11. 知识内容与业务领域

**两版：[沿用]** 服务启动时均注入理财产品、7 天退款、开户流程三条演示文档；RAG 和合规提示词也仍包含金融产品/金融监管用语。参见 [当前知识注入](../../mall-customer/api/main.py#L55)、[参考知识注入](../../../smart-cs-multi-agent-main/python-impl/api/main.py#L51)、[RAG 提示](../../mall-customer/agents/knowledge_rag.py#L17)、[合规提示](../../mall-customer/agents/compliance_checker.py#L38)。

**风险：** 这不是商城商品、物流、售后政策的可靠知识源。启动时重复调用 `add_document()`，内存文档列表也没有按 ID 去重；若再引入磁盘索引，需要关注重复文档、索引与元数据一致性。应将静态政策和实时订单/库存分开：前者版本化入库，后者走商城业务接口。

### 12. 工单意图分析

**参考版：[沿用]** 工单 Agent 只把最新用户消息交给 LLM，要求返回 `create/query/update` 等 JSON；JSON 解析失败默认 `create`。参见 [参考工单分析](../../../smart-cs-multi-agent-main/python-impl/agents/ticket_handler.py#L113)。

**当前版：[改造]** 将最近 10 条历史格式化进提示词，要求已存在工单走 `query/update`；允许从模型 JSON 或历史正则提取 `TK-YYYYMMDD-XXXXXX` 工单号，并容忍模型把 JSON 包进 Markdown 代码块。参见 [分析提示](../../mall-customer/agents/ticket_handler.py#L44)、[历史格式化](../../mall-customer/agents/ticket_handler.py#L210)、[工单号提取](../../mall-customer/agents/ticket_handler.py#L219)、[处理入口](../../mall-customer/agents/ticket_handler.py#L246)。

**作用与边界：** “刚才那个工单”比参考版更可能识别正确。但从历史倒序取最近工单号，不能保证它就是用户当前指代的工单；超过窗口的工单号也会消失。工单 ID 应作为结构化实体记录；有多个候选时应向用户确认。

### 13. 工单执行与持久化

**参考版：[沿用]** `TicketStore` 用 Python 字典，支持创建、按 ID 查询和更新状态；不进入商城数据库。参见 [参考工单存储](../../../smart-cs-multi-agent-main/python-impl/agents/ticket_handler.py#L69)。

**当前版：[小幅新增]** 仍用进程内 `TicketStore`，增加 `update_priority()`；`query_ticket()` 和 `update_priority()` 只按工单号读取，没有传入当前 `user_id` 做归属校验。参见 [当前存储](../../mall-customer/agents/ticket_handler.py#L79)、[优先级更新](../../mall-customer/agents/ticket_handler.py#L107)、[工单查询](../../mall-customer/agents/ticket_handler.py#L185)。

**风险：** 重启、多个 Python 实例、服务迁移都会使工单不可查或不一致。若 `action` 为 `query/update` 但没有找到工单号，当前分支会走 `create_ticket()`，造成“查进度”误建新单；JSON 解析失败也默认创建。参见 [失败默认创建](../../mall-customer/agents/ticket_handler.py#L144)、[分支落点](../../mall-customer/agents/ticket_handler.py#L264)。这应优先改为追问或明确失败，不应自动创建。

### 14. 子 Agent 输出如何进入状态

**参考版：[沿用]** 知识/工单结果写入 `sub_results` 字典；合规结果也写入该字典，汇总时曾把字典混进字符串拼接。参见 [参考状态](../../../smart-cs-multi-agent-main/python-impl/agents/supervisor.py#L30)、[参考合规结果](../../../smart-cs-multi-agent-main/python-impl/agents/compliance_checker.py#L186)、[参考汇总](../../../smart-cs-multi-agent-main/python-impl/agents/supervisor.py#L102)。

**当前版：[改造]** 知识、工单、闲聊 Agent 将回复写为 `AIMessage`；`sub_results` 和 `final_response` 从状态移除。合规只检查末尾 `AIMessage` 并返回布尔结果。参见 [当前状态](../../mall-customer/agents/supervisor.py#L35)、[知识输出](../../mall-customer/agents/knowledge_rag.py#L139)、[工单输出](../../mall-customer/agents/ticket_handler.py#L278)、[合规输入](../../mall-customer/agents/compliance_checker.py#L186)。

**作用与边界：** 消除了汇总时的类型混用，让回答自然成为下一轮历史。代价是草稿先进入图状态；虽可在合规不通过时撤回末尾消息，但业务副作用不会随消息撤回。

### 15. 合规检查和最终回复

**参考版：[沿用]** 规则检查 + LLM 检查，之后 Supervisor 拼接子结果；若不通过则返回固定转人工话术。参见 [参考合规](../../../smart-cs-multi-agent-main/python-impl/agents/compliance_checker.py#L155)、[参考汇总](../../../smart-cs-multi-agent-main/python-impl/agents/supervisor.py#L102)。

**当前版：[改造]** 检查业务 Agent 的末尾 AI 草稿；不通过则 `RemoveMessage` 撤回草稿、追加固定话术；通过则直接保留草稿，避免追加一份相同的 AI 回复。参见 [当前合规](../../mall-customer/agents/compliance_checker.py#L186)、[当前合成](../../mall-customer/agents/supervisor.py#L127)。

**风险：** 图顺序是 `ticket_handler → compliance_check`，因此拒绝输出时工单可能已经创建/修改。固定话术说“工单编号已自动生成”，但直达合规分支和其他拒绝场景没有对应创建动作。合规 LLM 的 JSON 无法解析时会默认 `passed=True`。参见 [图边](../../mall-customer/agents/supervisor.py#L238)、[固定话术](../../mall-customer/agents/supervisor.py#L137)、[解析失败处理](../../mall-customer/agents/compliance_checker.py#L143)。

### 16. HTTP 返回与流式显示

**参考版：[沿用]** 先 `graph.ainvoke()`，成功后返回含回复、会话 ID、意图和合规结果的 JSON；异常返回 HTTP 500。参见 [参考 API](../../../smart-cs-multi-agent-main/python-impl/api/main.py#L99)。

**当前版：[改造]** 先等待 `graph.ainvoke()` 完成，再把完整文本按 4 字分块、每块暂停 30 ms 后发送 SSE；异常也被转为普通回复文本，末尾仍发 `[DONE]`。Java 拼接块并在流正常完成时保存，前端逐块渲染。参见 [Python SSE](../../mall-customer/api/main.py#L106)、[Java 拼接和落库](../../mall-server/src/main/java/com/supermarket/service/impl/MessageServiceImpl.java#L77)、[前端读取](../../mall-portal/src/components/CustomerModal.vue#L237)。

**区别与边界：** 这是“完整生成后的打字机显示”，不是模型 token 真流式；首字等待仍包含整轮路由、RAG/工单、合规耗时。异常文字会作为正常客服消息返回并可能落库，且把内部异常细节暴露给用户；应采用结构化 `error` SSE 事件或非成功状态，并单独处理落库。

### 17. MCP 工具与监控

**两版：[沿用且未接入主图]** `MCPToolServer`、`order_query`、`knowledge_search`、`ticket_create`、`risk_check` 与 API 的 `/api/tools`、`/api/tools/call` 基本相同；当前图的知识/工单 Agent 没有调用这些工具。`order_query` 固定返回演示订单和金融产品，`knowledge_search` 返回拼接的示例片段，`ticket_create` 只生成一个号。参见 [工具定义](../../mall-customer/mcp/mcp_server.py#L193)、[工具 API](../../mall-customer/api/main.py#L171)、[图节点初始化](../../mall-customer/agents/supervisor.py#L209)。

**准确表述：** 当前系统“提供了工具服务示例”，不能据此说 Agent 已能查询商城真实订单、创建商城工单。OpenTelemetry 包装和指标代码也主要沿用参考版；要评估准确率，仍需增加带标注样本的业务评测。

## 用四个真实提问检查上述差异

| 用户消息 | 当前代码的可能路径 | 可核实的问题 | 目标行为 |
| --- | --- | --- | --- |
| “你好” | Supervisor → chitchat → 合规 → SSE | 新增闲聊分支确实存在；仍需一次路由模型和一次闲聊模型调用 | 简短回复；业务检索次数为 0 |
| “这个商品能退吗？” | Supervisor → RAG → 合规 | RAG 只取本轮“这个商品”，现有知识仍是金融示例；不能据此给出商城退款承诺 | 从已确认的商品/订单实体补全问题，查适用政策并标明来源；缺实体则追问 |
| “查一下刚才那个工单” | Supervisor → ticket → 合规 | 历史可能提取工单号；若没有号，当前代码会新建工单 | 找到且核对归属后查询；没有唯一工单则追问；新增工单数为 0 |
| “给刚才的单子加急” | Supervisor → ticket.update → 合规 | 当前只更新内存字典的优先级；合规检查在修改之后 | 核验用户、订单/工单和加急规则后持久化；失败时不改变数据 |

这些是按代码推导的路径和边界，不是模型真实路由命中率的测试结论。

## 精确改造建议：按依赖顺序实施

### P0：先保证业务动作不会做错

1. 将 `TicketStore` 换成持久化工单服务，工单记录至少包含 `ticket_id`、`user_id`、关联 `order_id`、类型、状态、优先级、创建/更新时间、幂等请求 ID。
2. 工单命令使用有校验的结构化对象：`action ∈ {create, query, update}`。`query/update` 缺少或无法唯一确定 `ticket_id` 时返回 `needs_clarification`，不能走 `create`；模型 JSON 解析失败也不能自动创建。
3. 读取或修改工单时同时校验登录用户归属。先校验身份、订单状态与业务规则，再执行持久化操作；对重复提交用幂等 ID 返回原结果。
4. 将“已创建工单”“已转人工”等话术绑定真实业务结果。没有成功记录时只说明“暂未完成”，不要伪称成功。

### P1：把回答建立在商城事实之上

1. 清除理财/开户演示知识，整理商城政策文档：来源 ID、适用商品/类目、发布时间、生效时间、版本、责任人。启动时按版本加载，避免重复追加。
2. 用真正的文本 embedding 或经过验证的关键词/混合检索替换 `_simple_embedding()`；建立相关性阈值与无答案分支，限制重排索引在 `0 <= i < len(documents)` 并去重、截到 `top_k`。
3. 商品价格、库存、订单、物流等变化数据从商城真实服务读取，并由服务端使用已认证的 `user_id` 校验权限；RAG 只负责相对稳定的政策解释。
4. 让 RAG 回答附带可追溯的政策或商品来源。对“这个”“那单”先解析指代，不能解析时追问。

### P2：改进编排与对话状态

1. 在 Supervisor 前接入结构化意图识别：至少输出 `intent`、`action`、`entities`、`missing_fields`、`confidence`，区分“问退款规则”“查退款进度”“申请退款”“投诉退款”。决定是复用并改写 `IntentRouterAgent`，还是删除它并把相同结构放入 Supervisor；避免两套未一致的提示词。
2. 在 checkpoint 中单独保存当前 `active_order_id`、`active_ticket_id` 和待补全字段。消息窗口可以裁剪，但业务对象不随旧文本消失。多个候选对象时要求用户选择。
3. 区分“生成回复前的业务校验”和“生成回复后的内容审查”。对合规 LLM 无法解析、超时、空输出等情况建立明确失败策略与指标。
4. 对真正需要低首字延迟的场景再改为模型流式输出，同时保证未经审查的敏感片段不会提前发送。把错误作为独立事件传递，Java 不将错误文本保存为正常客服回复。

## 建议验收用例

| 用例 | 应观察的结果 |
| --- | --- |
| “查进度”但没有工单号和历史 | 追问工单信息；新增工单数为 0 |
| 历史中有两个不同工单，用户说“那个” | 追问指代；不任取最近字符串执行更新 |
| 用户提供别人的工单号或订单号 | 拒绝访问；不泄露状态；不修改数据 |
| 同一创建请求重试两次 | 返回同一个工单结果；数据库只有一条 |
| Redis 不可用或服务重启 | 明确记录降级状态；用户历史仍可从 MySQL 查看；对话上下文的降级行为可预期 |
| “这件商品还有库存吗” | 使用商城实时数据；不从旧政策文档猜库存 |
| 知识库无适用退款政策 | 说明无法确认并转人工/引导查询；不给出金融示例中的“7 天”承诺 |
| 模型返回非法 JSON 或合规接口失败 | 不创建工单、不默认放行高风险内容；返回可识别错误或人工处理结果 |
| Python 图失败、SSE 中断 | Java 不把异常堆栈或半段回复当正常客服消息保存 |

最先值得改的三处代码入口是 [工单 `process()`](../../mall-customer/agents/ticket_handler.py#L246)、[长期记忆 `_simple_embedding()`](../../mall-customer/memory/long_term_memory.py#L66)、[知识注入](../../mall-customer/api/main.py#L55)。它们分别决定业务动作是否误执行、检索是否有语义，以及回答所依据的内容是否属于当前商城。
