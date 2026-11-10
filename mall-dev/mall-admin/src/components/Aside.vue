<template>
  <div class="admin-aside h-full flex flex-col overflow-hidden">
    <div class="aside-brand h-50px flex items-center justify-center gap-8px border-b border-white/6 flex-shrink-0 overflow-hidden px-10px" :class="{ '!p-0': isCollapsed }">
      <span class="brand-mark text-white text-20px font-700">邻</span>
      <span v-show="!isCollapsed" class="text-white text-16px font-600 whitespace-nowrap tracking-1px">邻里优选后台</span>
    </div>

    <el-menu
      class="flex-1 overflow-y-auto overflow-x-hidden !border-r-none"
      :default-active="activeMenu"
      :collapse="isCollapsed"
      router
      :background-color="sidebarBg"
      :text-color="sidebarText"
      :active-text-color="sidebarActive"
    >
      <el-menu-item v-for="item in visibleMenus" :key="item.path" :index="item.path" @click="addTag(item)">
        <el-icon><component :is="item.icon" /></el-icon>
        <span>{{ item.name }}</span>
      </el-menu-item>
    </el-menu>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { useMenuStore } from '@/stores/modules/menu'
import { useUserStore } from '@/stores/modules/user'
import { useTagStore } from '@/stores/modules/tag'

const allMenus = [
  { name: '首页', path: '/home', icon: 'HomeFilled', role: 0 },
  { name: '用户管理', path: '/user', icon: 'UserFilled', role: 1 },
  { name: '分类管理', path: '/category', icon: 'Grid', role: 1 },
  { name: '商品管理', path: '/product', icon: 'Goods', role: 1 },
  { name: '订单管理', path: '/order', icon: 'Document', role: 1 },
  { name: '秒杀管理', path: '/seckill', icon: 'Lightning', role: 1 }
]

const route = useRoute()
const menuStore = useMenuStore()
const userStore = useUserStore()
const tagStore = useTagStore()
const isCollapsed = computed(() => menuStore.isCollapsed)
const activeMenu = computed(() => route.path)

const visibleMenus = computed(() => {
  const role = userStore.user?.role
  return allMenus.filter(m => role === 1 || m.role === 0)
})

const sidebarBg = 'var(--sidebar-bg)'
const sidebarText = 'var(--sidebar-text)'
const sidebarActive = 'var(--sidebar-text-active)'

function addTag(item) { tagStore.addTag({ id: 0, name: item.name, path: item.path, code: item.path.replaceAll('/', ':').substring(1) }) }
</script>

<style lang="scss" scoped>
.el-menu {
  &::-webkit-scrollbar { width: 4px; }
  &::-webkit-scrollbar-track { background: transparent; }
  &::-webkit-scrollbar-thumb { background: rgba(255, 255, 255, 0.12); border-radius: 2px; }
}
.admin-aside { background: var(--sidebar-bg); }
.aside-brand { background: var(--sidebar-logo-bg); }
.brand-mark { display: grid; place-items: center; width: 32px; height: 32px; border-radius: 10px; background: #398466; }
.admin-aside :deep(.el-menu-item) { margin: 4px 10px; border-radius: 10px; height: 44px; transition: background .2s; }
.admin-aside :deep(.el-menu-item:hover) { background: #285b44 !important; }
.admin-aside :deep(.el-menu-item.is-active) { background: #327457 !important; font-weight: 700; }
</style>

<style lang="scss">
/* 侧边栏弹出菜单（折叠时的子菜单弹层） */
.el-menu--popup {
  background: var(--sidebar-bg) !important;
  padding: 4px 0;

  .el-menu-item {
    color: var(--sidebar-text) !important;
    background-color: transparent !important;
    &:hover { background-color: rgba(255, 255, 255, 0.06) !important; }
    &.is-active { color: var(--sidebar-text-active) !important; }
  }
}

/* 侧边栏内 icon 颜色 */
.sidebar-menu .el-icon,
.sidebar-menu .el-sub-menu__icon-arrow {
  color: inherit !important;
}

/* 子菜单嵌套背景 */
.sidebar-menu .el-menu {
  background: var(--sidebar-sub-bg) !important;
}
</style>
