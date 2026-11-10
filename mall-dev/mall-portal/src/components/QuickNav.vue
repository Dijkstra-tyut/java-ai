<template>
  <div class="quicknav">
    <!-- 返回顶部：滚动超过 300px 触发，保留淡入淡出动画 -->
    <transition name="quicknav-fade">
      <a
          v-show="showTop"
          href="javascript:void(0)"
          class="quicknav-item"
          @click="scrollToTop"
          title="返回顶部"
      >
        <el-icon :size="20"><Top /></el-icon>
      </a>
    </transition>
    <router-link to="/cart" class="quicknav-item" title="购物车">
      <el-icon :size="20"><ShoppingCart /></el-icon>
      <span class="tip">购物车</span>
    </router-link>
    <router-link to="/userinfo" class="quicknav-item" title="个人信息">
      <el-icon :size="20"><User /></el-icon>
      <span class="tip">个人信息</span>
    </router-link>
    <button type="button" class="quicknav-item quicknav-service" title="智能客服" aria-label="打开智能客服" @click="openCustomer">
      <el-icon :size="20"><ChatDotRound /></el-icon>
      <span class="tip">智能客服</span>
    </button>
  </div>
  <CustomerModal ref="customerRef" />
</template>

<script setup>
import { ref, onMounted, onUnmounted } from 'vue'
import { ShoppingCart, User, Top, ChatDotRound } from '@element-plus/icons-vue'
import { useAuthStore } from '@/stores/auth'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import CustomerModal from './CustomerModal.vue'

const showTop = ref(false)
const customerRef = ref(null)
const authStore = useAuthStore()
const router = useRouter()

function openCustomer() {
  if (!authStore.isLogin) {
    ElMessage.info('登录后即可使用智能客服')
    router.push('/login')
    return
  }
  customerRef.value?.open()
}

const scrollToTop = () => window.scrollTo({ top: 0, behavior: 'smooth' })

const handler = () => {
  showTop.value = window.scrollY > 300
}
onMounted(() => {
  window.addEventListener('scroll', handler, { passive: true })
})
onUnmounted(() => window.removeEventListener('scroll', handler))
</script>

<style>
.quicknav { position: fixed; right: 20px; bottom: 28px; z-index: 99; display: flex; flex-direction: column; gap: 8px; }
.quicknav-item { width: 44px; height: 44px; display: flex; align-items: center; justify-content: center;
  background: #fff; border: 1px solid #dce8df; border-radius: 14px; color: #365947; text-decoration: none;
  position: relative; transition: all .2s; cursor: pointer; box-shadow: 0 6px 22px rgba(18, 60, 39, .1); }
.quicknav-item:hover { color: #21694f; border-color: #21694f; background: #eef7f1; box-shadow: 0 2px 8px rgba(33,105,79,0.1); }
.quicknav-service { background: #21694f; color: #fff; border-color: #21694f; width: 52px; height: 52px; margin-left: -4px; border-radius: 18px; }
.quicknav-service:hover { background: #18543e; color: #fff; transform: translateY(-2px); }
.quicknav-item:focus-visible { outline: 3px solid #f6b84b; outline-offset: 2px; }
.quicknav-item .tip { position: absolute; right: 54px; background: #333; color: #fff; font-size: 12px;
  padding: 4px 10px; border-radius: 4px; white-space: nowrap; opacity: 0; pointer-events: none; transition: opacity .2s; }
.quicknav-item:hover .tip { opacity: 1; }

/* 仅针对“返回顶部”的淡入淡出动画 */
.quicknav-fade-enter-active, .quicknav-fade-leave-active { transition: opacity .3s, transform .3s; }
.quicknav-fade-enter-from, .quicknav-fade-leave-to { opacity: 0; transform: translateY(10px); }
@media (max-width: 640px) { .quicknav { right: 12px; bottom: 16px; } }
</style>
