# 邻里优选超市（本地开发项目）

这是一个用于学习前后端联调和后端业务设计的商城项目。`mall-server` 是 Spring Boot 单体后端；`mall-portal` 是用户商城；`mall-admin` 是管理后台；`mall-customer` 是后续单独改造的智能客服服务，当前启动流程不依赖它。

## 本地地址

| 模块 | 地址 | 说明 |
| --- | --- | --- |
| 后端 API | <http://localhost:8800> | Spring Boot 3 / Java 17+ |
| 用户商城 | <http://localhost:3001> | Vue 3 + Vite |
| 管理后台 | <http://localhost:3002/admin/> | Vue 3 + Vite |
| API 文档 | <http://localhost:8800/swagger-ui/index.html> | 后端启动后可访问 |

演示账号：管理端 `admin / 123456`，商城用户 `user / 123456`。这些账号只用于本地开发，不应部署到公开环境。

当前支付和配送均为本地演示流程：点击“模拟支付”只修改订单状态，不会扣款或向快递公司发单。

## 商品数据

`db/catalog.json` 存放品牌、型号或包装规格、示例价格、库存、商品页面来源和图片来源。当前有 7 个主分类、14 个子分类、23 个商品。商品图片保存在 `img/product/`，由后端 `/portal/product/img` 提供。价格和库存是**演示数据**，不代表零售平台实时报价；商品规格以所列来源和实物包装为准。

`python db/build_catalog.py` 会重新获取图片并生成 `db/mall.sql`。导入该 SQL 会**替换 `mall` 数据库的全部现有表和数据**，请勿在有真实订单的数据库上执行。来源图片用于本地学习演示；公开部署前请确认图片使用授权并改为获授权的商品素材。

## 启动

### 方案 A：完整中间件

安装并启动 Docker 后，在项目根目录运行：

```powershell
docker compose -f docker/local/docker-compose.yml up -d
```

首次创建 MySQL 数据卷时会自动导入 `db/mall.sql`。如果已有旧的 MySQL 数据卷，需按需备份旧数据后手动导入新 SQL。

### 方案 B：本机 MySQL + Redis（当前开发环境）

MySQL 8 使用 `root / 123456`，Redis 监听 `127.0.0.1:6379` 且密码为 `123456`。先导入 `db/mall.sql`。这一方案不启动 RabbitMQ 和 Elasticsearch：普通订单超时由本地定时任务处理；商品搜索降级为 MySQL 查询；秒杀功能需要 RabbitMQ，暂不在商城导航中展示。

在 IDEA 中将 `mall-server/pom.xml` 导入为 Maven 项目，然后运行 `com.supermarket.MallApplication`，激活 `dev,local` profiles。命令行等价启动方式：

```powershell
cd mall-server
.\mvnw.cmd spring-boot:run '-Dspring-boot.run.profiles=dev,local'
```

若本机有 `OSS_ACCESS_KEY_ID` 等云服务环境变量，先清空这些变量；本地商品图片不依赖 OSS。`mall-server/.env.example` 给出了可选 OSS 配置模板。

两个前端分别启动：

```powershell
cd mall-portal
npm install
npm run dev
```

```powershell
cd mall-admin
npm install
npm run dev
```

门户的 `/portal-api/*` 由 Vite 转发到后端的 `/portal/*`；管理端的 `/admin-api/*` 转发到 `/admin/*`。配置分别见两个前端目录下的 `vite.config.*`。

## 后续学习与扩展

学习目标按以下顺序推进：先弄清前端请求、Vite 代理、后端 Controller、Service、数据库之间的联调链路；然后系统学习后端项目，普通增删改查只作简述，重点研究认证、缓存、订单、秒杀、消息队列等业务亮点。前端功能可以继续借助 AI 完成。智能客服改造、Excel 批量导入商品和其他 Agent 属于后续迭代。原项目采用 GPL-3.0，许可证见 `LICENSE`。
