<template>
  <div class="home" v-loading="loading">
    <div class="wrapper">
      <section class="market-grid" aria-label="首页导览">
        <aside class="category-rail">
          <h2>☷ 逛逛分类</h2>
          <template v-if="rootCats.length">
            <router-link v-for="(cat, index) in rootCats.slice(0, 9)" :key="cat.id" :to="`/category/${cat.id}`" class="rail-link">
              <span>{{ categoryIcons[index % categoryIcons.length] }}</span>{{ cat.name }} <b>›</b>
            </router-link>
          </template>
          <template v-else>
            <div v-for="(name, index) in categoryHints" :key="name" class="rail-link rail-hint"><span>{{ categoryIcons[index] }}</span>{{ name }} <b>›</b></div>
          </template>
          <p>每天发现一点生活灵感 ✦</p>
        </aside>
        <div class="campaigns">
          <div class="campaign-main">
            <div class="campaign-copy">
              <span class="campaign-label">邻里优选 · 今日推荐</span>
              <h1>好生活，从<br><em>逛一逛</em>开始</h1>
              <p>发现食品生鲜、家居日用与更多心头好</p>
              <a href="#home-categories" class="campaign-action">探索好物 <span aria-hidden="true">→</span></a>
            </div>
            <div class="campaign-art" aria-hidden="true"><span class="art-sun"></span><span class="art-bag">🛍️</span><span class="art-fruit">🍊</span></div>
          </div>
          <div class="campaign-bottom">
            <router-link to="/seckill" class="campaign-mini mini-orange"><small>限时发现</small><strong>秒杀专区</strong><span>看看正在进行的活动 →</span><i aria-hidden="true">⚡</i></router-link>
            <router-link to="/cart" class="campaign-mini mini-lilac"><small>购物清单</small><strong>喜欢的都收好</strong><span>去购物车看看 →</span><i aria-hidden="true">🛒</i></router-link>
          </div>
        </div>
        <aside class="service-rail">
          <div class="service-welcome"><span>✳</span><div><small>欢迎来到</small><strong>邻里优选</strong></div></div>
          <p>从发现好物，到轻松下单，日常购物更简单。</p>
          <router-link :to="authStore.isLogin ? '/userinfo' : '/login'" class="login-action">{{ authStore.isLogin ? '进入个人中心' : '登录 / 注册' }}</router-link>
          <div class="service-shortcuts"><router-link to="/orders">📦<span>我的订单</span></router-link><router-link to="/cart">🛒<span>购物车</span></router-link><router-link to="/userinfo">👤<span>个人中心</span></router-link></div>
          <div class="service-note">💬 <div><strong>购物有疑问？</strong><small>点击右下角，找智能客服聊聊</small></div></div>
        </aside>
      </section>

      <section class="benefit-row" aria-label="购物导览">
        <div class="benefit benefit-peach">🍑 <span><strong>发现心头好</strong><small>从熟悉的日常开始</small></span></div>
        <div class="benefit benefit-mint">🧺 <span><strong>品类更好逛</strong><small>按分类快速探索</small></span></div>
        <div class="benefit benefit-yellow">⚡ <span><strong>活动随时看</strong><small>进入秒杀专区</small></span></div>
        <div class="benefit benefit-blue">💬 <span><strong>问题随时问</strong><small>智能客服帮你解答</small></span></div>
      </section>

      <section class="inspiration-section" aria-label="生活灵感">
        <header class="section-head"><div><small>INSPIRATION</small><h2>生活灵感橱窗</h2></div><span>从细节里，发现家的新鲜感</span></header>
        <div class="inspiration-grid">
          <div v-for="card in inspirationCards" :key="card.title" class="inspiration-card">
            <img :src="card.image" :alt="card.title" loading="lazy" />
            <div><strong>{{ card.title }}</strong><span>{{ card.caption }}</span></div>
          </div>
        </div>
      </section>

      <section id="home-categories" class="category-section">
        <header class="section-head"><div><small>EXPLORE</small><h2>逛逛好物分类</h2></div><span>从喜欢的品类出发，发现更多选择</span></header>
        <div v-if="rootCats.length" class="category-grid">
          <router-link v-for="(cat, index) in rootCats" :key="cat.id" :to="`/category/${cat.id}`" class="category-tile" :class="`tone-${index % 6}`"><span>{{ categoryIcons[index % categoryIcons.length] }}</span><strong>{{ cat.name }}</strong><small>去看看 ↗</small></router-link>
        </div>
        <div v-else class="category-pending">商品分类将在服务连接后显示。先从上方了解商城功能吧。</div>
      </section>

    <!-- Product Sections -->
    <section v-for="cat in homeData" :key="cat.category.id" class="section">
      <header class="section-head">
        <div><small>PICKED FOR YOU</small><h2>{{ cat.category.name }}</h2></div>
        <div v-if="cat.children?.length" class="section-tags">
          <router-link v-for="c in cat.children" :key="c.id" :to="`/category/${c.id}`">{{ c.name }}</router-link>
        </div>
      </header>

      <div class="grid">
        <ProductCard v-for="p in cat.products?.slice(0, 8)" :key="p.id"
          :product="p" :image-key="cat.productImages?.[p.id] || ''"
          :seckill-info="cat.seckillMap?.[p.id] || null" @buy="buyNowHandler" />
      </div>
    </section>

    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { getHomeData } from '../api'
import { useAuthStore } from '@/stores/auth'
import ProductCard from '../components/ProductCard.vue'
import vaseImage from '@/assets/img/temp/vase01.jpg'
import tableImage from '@/assets/img/temp/zb01.jpg'
import decorImage from '@/assets/img/temp/xx01.jpg'
import artImage from '@/assets/img/temp/sec101.jpg'

const router = useRouter()
const authStore = useAuthStore()
const homeData = ref([])
const loading = ref(false)
const rootCats = computed(() => homeData.value.map(c => c.category))
const categoryIcons = ['🥬', '🧴', '🏠', '👕', '💻', '🎒', '🍊', '☕', '🎁']
const categoryHints = ['食品生鲜', '家居日用', '服饰出行', '数码家电', '更多灵感']
const inspirationCards = [
  { title: '鲜花与花器', caption: '给日常加一点明亮', image: vaseImage },
  { title: '餐桌时光', caption: '认真对待每一餐', image: tableImage },
  { title: '香氛小物', caption: '让空间更有温度', image: decorImage },
  { title: '墙面布置', caption: '装点生活的角落', image: artImage }
]

const buyNowHandler = (productId) => {
  if (!authStore.isLogin) { router.push('/login'); return }
  router.push({ name: 'Checkout', query: { productId, amount: 1 } })
}

;(async () => {
  loading.value = true
  try { const res = await getHomeData(); homeData.value = res.data || [] }
  catch { /* 服务未连接时保留导览内容 */ }
  finally { loading.value = false }
})()
</script>

<style scoped>
.wrapper { width: min(1320px, calc(100% - 32px)); margin: 0 auto; box-sizing: border-box; }
.home { background: #fbfaf7; padding: 22px 0 50px; color: #273b2f; }
.market-grid { display: grid; grid-template-columns: 205px minmax(0,1fr) 240px; gap: 16px; align-items: stretch; }
.category-rail, .service-rail { background: #fff; border: 1px solid #f0eae3; border-radius: 20px; padding: 18px; box-shadow: 0 8px 28px rgba(52,66,43,.035); }
.category-rail h2 { margin: 0 0 12px; font-size: 16px; color: #1b4e38; }
.rail-link { display: flex; align-items: center; gap: 10px; min-height: 40px; padding: 0 7px; border-radius: 10px; text-decoration: none; color: #34443a; font-size: 13px; }
.rail-link:hover { background: #fff2e9; color: #ed5b2c; }.rail-link span { font-size: 17px; }.rail-link b { margin-left: auto; color: #b7bbb4; font-size: 20px; font-weight: 400; }
.rail-hint { color: #56645a; }.category-rail p { border-top: 1px dashed #e8e9df; padding-top: 16px; margin: 10px 0 0; color: #87968b; font-size: 11px; }
.campaigns { min-width: 0; display: flex; flex-direction: column; gap: 14px; }
.campaign-main { min-height: 292px; border-radius: 22px; overflow: hidden; background: linear-gradient(115deg, #ff6346 0%, #ff8951 58%, #ffc66b 100%); position: relative; display: flex; align-items: center; }
.campaign-main::before { content: ''; position: absolute; width: 370px; height: 370px; border: 1px solid rgba(255,255,255,.22); border-radius: 50%; right: -55px; top: -95px; box-shadow: 0 0 0 55px rgba(255,255,255,.07), 0 0 0 105px rgba(255,255,255,.04); }
.campaign-copy { position: relative; z-index: 1; padding: 34px; color: #fff; }.campaign-label { display: inline-block; border-radius: 999px; background: rgba(255,255,255,.22); padding: 6px 12px; font-size: 11px; font-weight: 700; letter-spacing: .08em; }
.campaign-copy h1 { font-size: clamp(29px, 3vw, 42px); line-height: 1.18; letter-spacing: .02em; margin: 16px 0 9px; font-weight: 900; }.campaign-copy h1 em { font-style: normal; color: #fff4b2; }.campaign-copy p { margin: 0; font-size: 13px; color: #fff7e9; }
.campaign-action { display: inline-flex; gap: 18px; align-items: center; margin-top: 20px; border-radius: 999px; background: #fff; color: #e85229; padding: 10px 17px; font-size: 13px; font-weight: 800; text-decoration: none; }.campaign-action:hover { background: #fff6e6; }
.campaign-art { position: absolute; inset: 0; pointer-events: none; }.art-sun { position: absolute; right: 8%; top: 21%; width: 155px; height: 155px; border-radius: 50%; background: #ffe599; box-shadow: 0 20px 55px rgba(182,57,19,.17); }.art-bag { position: absolute; right: 10%; top: 20%; font-size: 112px; filter: drop-shadow(0 20px 18px rgba(159,57,29,.22)); transform: rotate(12deg); }.art-fruit { position: absolute; right: 32%; bottom: 7%; font-size: 65px; transform: rotate(-16deg); }
.campaign-bottom { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; flex: 1; }.campaign-mini { min-height: 126px; border-radius: 18px; padding: 18px 20px; display: flex; flex-direction: column; position: relative; overflow: hidden; text-decoration: none; transition: transform .2s; }.campaign-mini:hover { transform: translateY(-3px); }
.mini-orange { background: #fff0ce; color: #9e4b13; }.mini-lilac { background: #eee7ff; color: #5c458e; }.campaign-mini small { font-size: 11px; font-weight: 800; opacity: .78; }.campaign-mini strong { margin-top: 7px; font-size: 22px; }.campaign-mini > span { margin-top: auto; font-size: 12px; font-weight: 600; }.campaign-mini i { position: absolute; right: 16px; top: 26px; font-style: normal; font-size: 54px; opacity: .8; transform: rotate(12deg); }
.service-rail { display: flex; flex-direction: column; }.service-welcome { display: flex; align-items: center; gap: 12px; }.service-welcome > span { width: 42px; height: 42px; display: grid; place-items: center; border-radius: 13px; background: #daf2dc; color: #218055; font-size: 28px; }.service-welcome small { display: block; font-size: 11px; color: #839184; }.service-welcome strong { display: block; margin-top: 4px; color: #1b4e38; font-size: 17px; }
.service-rail > p { margin: 20px 0; font-size: 13px; line-height: 1.6; color: #6b796e; }.login-action { display: block; text-align: center; border-radius: 11px; padding: 12px; background: #257a55; color: #fff; font-size: 13px; font-weight: 800; text-decoration: none; }.login-action:hover { background: #186342; }
.service-shortcuts { display: grid; grid-template-columns: repeat(3,1fr); gap: 4px; padding: 19px 0; border-bottom: 1px solid #eeeae3; }.service-shortcuts a { display: flex; flex-direction: column; align-items: center; gap: 7px; color: #68776d; font-size: 22px; white-space: nowrap; text-decoration: none; }.service-shortcuts a span { font-size: 10px; }.service-shortcuts a:hover { color: #ef5b2d; }
.service-note { display: flex; gap: 10px; align-items: center; background: #f3f8f1; border-radius: 13px; margin-top: auto; padding: 12px; font-size: 24px; }.service-note strong { display: block; color: #276449; font-size: 12px; }.service-note small { display: block; color: #789381; margin-top: 5px; font-size: 10px; line-height: 1.4; }
.benefit-row { display: grid; grid-template-columns: repeat(4,1fr); gap: 14px; margin: 18px 0 44px; }.benefit { display: flex; align-items: center; gap: 12px; border-radius: 15px; padding: 15px; font-size: 29px; }.benefit strong, .benefit small { display: block; }.benefit strong { font-size: 13px; margin-bottom: 5px; }.benefit small { font-size: 11px; opacity: .65; }.benefit-peach { background: #ffe9e1; color: #a04a2c; }.benefit-mint { background: #e1f3e7; color: #2b704c; }.benefit-yellow { background: #fff0cf; color: #93610e; }.benefit-blue { background: #e6effa; color: #3b648d; }
.inspiration-section { margin-bottom: 42px; }.inspiration-grid { display: grid; grid-template-columns: repeat(4,1fr); gap: 15px; }.inspiration-card { background: #fff; border: 1px solid #f0eae3; border-radius: 17px; overflow: hidden; }.inspiration-card img { display: block; width: 100%; aspect-ratio: 1.5; object-fit: cover; }.inspiration-card > div { display: flex; align-items: baseline; justify-content: space-between; gap: 8px; padding: 13px 14px; }.inspiration-card strong { color: #304837; font-size: 14px; }.inspiration-card span { color: #9a968d; font-size: 11px; }
.category-section { scroll-margin-top: 150px; margin-bottom: 44px; }.category-grid { display: grid; grid-template-columns: repeat(6,1fr); gap: 12px; }.category-tile { min-height: 132px; border-radius: 17px; padding: 15px; display: flex; flex-direction: column; text-decoration: none; color: #34453b; transition: transform .2s; }.category-tile:hover { transform: translateY(-4px); }.category-tile > span { font-size: 32px; }.category-tile strong { margin-top: 6px; font-size: 14px; }.category-tile small { margin-top: auto; font-size: 11px; opacity: .7; }.tone-0 { background: #e7f4de; }.tone-1 { background: #ffe9dc; }.tone-2 { background: #f4e8fb; }.tone-3 { background: #e1f2f8; }.tone-4 { background: #fff0ce; }.tone-5 { background: #fce4e6; }.category-pending { border-radius: 15px; background: #fff; border: 1px dashed #e8e5de; color: #8b9488; padding: 22px; font-size: 12px; }
.section-head { border: 0; padding: 0; display: flex; align-items: end; justify-content: space-between; gap: 16px; margin-bottom: 20px; }.section-head small { color: #f16a3b; font-size: 11px; font-weight: 900; letter-spacing: .16em; }.section-head h2 { margin: 5px 0 0; font-size: 25px; color: #203d2e; }.section-head > span { font-size: 12px; color: #829083; }
.section-tags a { border-radius: 999px; background: #fff; padding: 8px 12px; color: #627464; font-size: 12px; }.product-section { margin-bottom: 42px; }
@media (max-width: 1100px) { .market-grid { grid-template-columns: 185px minmax(0,1fr); }.service-rail { display: none; }.category-grid { grid-template-columns: repeat(4,1fr); } }
@media (max-width: 700px) { .market-grid { display: block; }.category-rail { display: none; }.campaign-main { min-height: 310px; }.campaign-copy { padding: 24px; }.campaign-copy p { max-width: 210px; line-height: 1.5; }.art-bag { font-size: 80px; right: 3%; top: 34%; }.art-sun { right: -40px; top: 36%; }.art-fruit { display: none; }.campaign-bottom { margin-top: 12px; }.campaign-mini { min-height: 116px; padding: 14px; }.campaign-mini strong { font-size: 17px; }.campaign-mini i { font-size: 34px; right: 8px; }.benefit-row, .inspiration-grid { grid-template-columns: repeat(2,1fr); gap: 8px; }.benefit { padding: 10px; font-size: 23px; }.benefit strong { font-size: 11px; }.benefit small { font-size: 10px; }.inspiration-card > div { flex-direction: column; }.category-grid, .grid { grid-template-columns: repeat(2,1fr); }.section-head { align-items: start; flex-direction: column; }.section-head h2 { font-size: 21px; } }
@media (max-width: 400px) { .campaign-bottom { gap: 8px; }.campaign-mini strong { font-size: 15px; }.category-grid { gap: 8px; } }

.section { margin-bottom: 56px; }
.section-tags { display: flex; gap: 12px; }
.section-tags a:hover { color: #ef5b2d; }
.grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 20px; }
@media (max-width: 1000px) { .grid { grid-template-columns: repeat(2, 1fr); } }
</style>
