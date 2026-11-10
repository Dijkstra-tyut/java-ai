<template>
  <div class="layout">
    <div class="announcement"><div class="wrapper announcement-inner"><span>✦ 邻里优选 · 发现日常好物</span><span>品类探索 / 便捷购物 / 智能客服</span></div></div>
    <!-- Header -->
    <header class="header" :class="{ 'is-sticky': isSticky }">
      <div class="header-top wrapper">
        <router-link to="/" class="logo">
          <span class="brand-mark"><b>邻</b><i>里</i></span>
          <span class="brand-copy"><span class="brand-name">邻里<span>优选</span></span><small>NEIGHBORHOOD MARKET</small></span>
        </router-link>

        <div class="header-actions">
          <form @submit.prevent="doSearch" class="search-form">
            <el-input ref="searchInputRef" v-model="keyword" placeholder="搜索你想要的好物" size="small" class="search-input"
              @keyup.enter="doSearch" clearable />
            <button type="submit" class="search-btn"><el-icon><Search /></el-icon><span>搜索</span></button>
          </form>

          <div class="user-links">
            <template v-if="!isLogin">
              <router-link to="/login">登录</router-link>
              <span class="divider">|</span>
              <router-link to="/register">注册</router-link>
            </template>
            <template v-else>
              <span class="greeting">{{ username }}</span>
              <span class="divider">|</span>
              <router-link to="/userinfo">个人信息</router-link>
              <span class="divider">|</span>
              <a @click="handleLogout">退出</a>
            </template>
          </div>

          <router-link to="/cart" class="cart-icon">
            <el-icon :size="20"><ShoppingCart /></el-icon>
            <span class="cart-badge" v-if="cartCount > 0">{{ cartCount }}</span>
          </router-link>
        </div>
      </div>

      <!-- Category Navigation -->
      <nav class="nav-bar">
        <div class="wrapper">
          <ul class="nav-list">
            <li class="nav-item">
              <router-link to="/" class="nav-link" exact-active-class="active">首页</router-link>
            </li>
            <li class="nav-item"><router-link to="/seckill" class="nav-link nav-feature">⚡ 秒杀专区</router-link></li>
            <li v-for="cat in rootCategories" :key="cat.id" class="nav-item"
              @mouseenter="hoverCat = cat.id" @mouseleave="hoverCat = null">
              <router-link :to="`/category/${cat.id}`" class="nav-link" :class="{ active: isCatActive(cat.id) }">
                {{ cat.name }}
                <span v-if="cat.children?.length" class="arrow">▾</span>
              </router-link>
              <transition name="dropdown">
                <div v-if="cat.children?.length && hoverCat === cat.id" class="sub-nav"
                  @mouseenter="hoverCat = cat.id" @mouseleave="hoverCat = null">
                  <router-link v-for="child in cat.children" :key="child.id"
                    :to="`/category/${child.id}`" class="sub-link">{{ child.name }}</router-link>
                </div>
              </transition>
            </li>
            <li class="nav-item"><router-link to="/orders" class="nav-link">我的订单</router-link></li>
          </ul>
        </div>
      </nav>
    </header>

    <!-- Spacer for sticky header -->
    <div class="header-spacer"></div>

    <!-- Main Content -->
    <main class="main-content"><router-view /></main>

    <!-- Footer -->
    <footer class="footer">
      <div class="footer-inner wrapper">
        <div><strong>邻里优选</strong><span>把日常所需，送到生活附近。</span></div>
        <div class="footer-links"><router-link to="/orders">我的订单</router-link><router-link to="/userinfo">个人中心</router-link></div>
      </div>
      <div class="footer-bottom">
        <p>邻里优选超市 · 本地开发演示</p>
        <p>商品价格和库存仅供功能演示</p>
      </div>
    </footer>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Search, ShoppingCart } from '@element-plus/icons-vue'


import { useAuthStore } from '@/stores/auth'
import { useUserStore } from '@/stores/user'
import { getCategories } from '../api'
import { getCartList } from '@/api/cart'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const userStore = useUserStore()
const searchInputRef = ref(null)
const keyword = ref('')
const isSticky = ref(false)
const hoverCat = ref(null)
const rootCategories = ref([])
const cartCount = ref(0)

const isLogin = computed(() => authStore.isLogin)
const username = computed(() => authStore.user?.name)

const isCatActive = (catId) => {
  if (route.name === 'ProductList') return Number(route.params.id) === catId
  return false
}

const doSearch = () => {
  if (!keyword.value.trim()) {
    ElMessage.warning('请输入搜索关键词')
    searchInputRef.value?.focus()
    return
  }
  router.push({ name: 'Search', query: { keyword: keyword.value.trim() } })
}

const handleLogout = () => {
  authStore.logout()
  userStore.clear()
  router.push('/')
}

const handleScroll = () => { isSticky.value = window.scrollY > 80 }

onMounted(async () => {
  window.addEventListener('scroll', handleScroll, { passive: true })
  try {
    const cats = await getCategories()
    rootCategories.value = cats.data || []
  } catch {}
  if (authStore.isLogin) {
    try {
      const cart = await getCartList()
      cartCount.value = cart?.data?.length || 0
    } catch {}
  }
})

onUnmounted(() => window.removeEventListener('scroll', handleScroll))
</script>

<style scoped>
/* ====== Header ====== */
.announcement { background: linear-gradient(90deg, #ff6948, #f03954 64%, #d93469); color: #fff; font-size: 12px; }
.announcement-inner { min-height: 30px; display: flex; align-items: center; justify-content: space-between; gap: 12px; font-weight: 600; letter-spacing: .06em; }
.header { position: relative; z-index: 100; background: #fff; box-shadow: 0 6px 24px rgba(25, 75, 49, .06); }
.header.is-sticky { position: fixed; top: 0; left: 0; right: 0; }

.wrapper { width: min(1160px, calc(100% - 32px)); margin: 0 auto; }

/* Top bar */
.header-top { display: flex; align-items: center; min-height: 90px; gap: 30px; }
.logo { flex-shrink: 0; display: flex; align-items: center; gap: 10px; text-decoration: none; }
.brand-mark { display: flex; align-items: center; width: 62px; height: 54px; position: relative; color: #fff; font-style: normal; transform: rotate(-5deg); }
.brand-mark b, .brand-mark i { display: grid; place-items: center; font-style: normal; font-weight: 900; font-size: 25px; box-shadow: 0 4px 10px rgba(39,86,52,.14); }
.brand-mark b { width: 42px; height: 46px; border-radius: 14px 14px 10px 14px; background: #247a55; }
.brand-mark i { width: 33px; height: 34px; border-radius: 11px; background: #ff683a; font-size: 19px; position: absolute; right: 0; bottom: 0; transform: rotate(12deg); border: 3px solid #fff; }
.brand-copy { display: flex; flex-direction: column; gap: 2px; }
.brand-name { display: block; color: #183d2d; font-size: 25px; font-weight: 900; white-space: nowrap; letter-spacing: -.04em; line-height: 1; }
.brand-name span { color: #f26332; }
.brand-copy small { font-size: 9px; color: #7d9280; letter-spacing: .13em; font-weight: 800; }

.header-actions { display: flex; align-items: center; gap: 20px; flex: 1; justify-content: flex-end; }

/* Search */
.search-form { display: flex; align-items: center; width: min(520px, 43vw); height: 42px; border: 2px solid #f26332; border-radius: 22px; overflow: hidden; }
.search-input { flex: 1; min-width: 0; }
.search-input :deep(.el-input__wrapper) { border-radius: 0; border: none; box-shadow: none; padding-left: 18px; }
.search-btn { width: 90px; height: 100%; border: none; border-radius: 18px; gap: 5px;
  background: #f26332; cursor: pointer; display: flex; align-items: center; justify-content: center;
  color: #fff; transition: all .2s; }
.search-btn:hover { background: #dd4d22; color: #fff; }

/* User links */
.user-links { display: flex; align-items: center; gap: 6px; font-size: 13px; white-space: nowrap; }
.user-links a { color: #555; text-decoration: none; cursor: pointer; transition: color .2s; }
.user-links a:hover { color: #21694f; }
.greeting { color: #333; font-size: 13px; }
.divider { color: #ddd; }

/* Cart icon */
.cart-icon { position: relative; color: #555; transition: color .2s; display: flex; align-items: center; }
.cart-icon:hover { color: #21694f; }
.cart-badge { position: absolute; top: -8px; right: -10px; background: #21694f; color: #fff;
  font-size: 11px; min-width: 18px; height: 18px; border-radius: 9px; display: flex;
  align-items: center; justify-content: center; padding: 0 4px; }

/* Nav bar */
.nav-bar { background: #fff; border-top: 1px solid #f2f0ec; border-bottom: 1px solid #f2f0ec; }
.nav-list { display: flex; flex-wrap: wrap; justify-content: flex-start; list-style: none; padding: 0; margin: 0; }
.nav-item { position: relative; }
.nav-link { display: block; padding: 13px 18px; font-size: 14px; color: #333; text-decoration: none;
  font-weight: 500; transition: color .2s; white-space: nowrap; }
.nav-link:hover, .nav-link.active { color: #ef5b2d; background: #fff5ef; }
.nav-feature { color: #ef5b2d; font-weight: 800; }
.nav-link.seckill-nav { color: #21694f; font-weight: 600; position: relative; }
.nav-link.seckill-nav::before { content: '⚡'; margin-right: 4px; font-size: 13px; }
.nav-link.seckill-nav:hover { color: #14543c; }
.nav-link .arrow { font-size: 10px; margin-left: 2px; }

/* Sub nav dropdown */
.sub-nav { position: absolute; top: 100%; left: 0; min-width: 140px; background: #fff;
  border: 1px solid #eee; border-radius: 0 0 8px 8px; box-shadow: 0 6px 20px rgba(0,0,0,0.08);
  padding: 8px 0; z-index: 102; }
.sub-link { display: block; padding: 8px 20px; font-size: 14px; color: #555; text-decoration: none;
  transition: all .15s; }
.sub-link:hover { color: #21694f; background: #eaf4ec; }

.dropdown-enter-active { transition: all .2s ease-out; }
.dropdown-leave-active { transition: all .15s ease-in; }
.dropdown-enter-from, .dropdown-leave-to { opacity: 0; transform: translateY(-4px); }

/* Spacer */
.header-spacer { height: 0; }
.header.is-sticky + .header-spacer { height: 132px; }
.header:not(.is-sticky) + .header-spacer { height: 0; }

/* Main */
.main-content { min-height: 500px; }

/* ====== Footer ====== */
.footer { margin-top: 60px; background: #173b2e; color: #e6f2e8; }
.footer-inner { min-height: 106px; display: flex; align-items: center; justify-content: space-between; gap: 16px; }
.footer-inner strong { display: block; font-size: 19px; margin-bottom: 8px; }
.footer-inner span { color: #adc8b5; font-size: 13px; }
.footer-links { display: flex; gap: 20px; font-size: 13px; }
.footer-links a { color: #d9ebde; text-decoration: none; }
.footer-links a:hover { color: #fff; text-decoration: underline; }
.footer-service { display: flex; padding: 30px 0; border-top: 1px solid #eee; border-bottom: 1px solid #eee; }
.service-item { flex: 1; text-align: center; }
.service-item:not(:last-child) { border-right: 1px solid #eee; }
.service-item img { display: block; margin: 0 auto; width: 44px; height: 44px; opacity: 0.7; }
.service-item span { display: block; margin-top: 12px; font-size: 15px; color: #666; }
.footer-bottom { background: #103126; padding: 16px 0; text-align: center; }
.footer-bottom p { margin: 4px 0; color: #999; font-size: 12px; line-height: 1.8; }
@media (max-width: 1100px) {
  .nav-link { padding: 10px 12px; font-size: 14px; }
}
@media (max-width: 700px) {
  .announcement-inner span:last-child { display: none; }
  .header-top { flex-wrap: wrap; gap: 12px; padding: 12px 0; }
  .header-actions { width: 100%; justify-content: space-between; gap: 8px; }
  .search-form { width: min(230px, 48vw); height: 36px; }
  .search-btn { width: 40px; }
  .search-btn span { display: none; }
  .nav-list { flex-wrap: nowrap; overflow-x: auto; justify-content: flex-start; }
  .nav-link { padding: 11px 14px; }
  .header.is-sticky + .header-spacer { height: 154px; }
  .footer-inner { padding: 24px 0; align-items: flex-start; flex-direction: column; }
}
</style>
