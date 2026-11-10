<template>
  <div class="admin-shell h-screen flex">
    <div
      class="layout-sidebar"
      :style="{ width: isCollapsed ? 'var(--sidebar-collapsed-width)' : 'var(--sidebar-width)' }"
    >
      <Aside />
    </div>
    <div class="layout-right">
      <header class="layout-header"><Header /></header>
      <div class="layout-tags"><Tag /></div>
      <main class="layout-main"><router-view /></main>
    </div>
  </div>
</template>

<script setup>
import { computed, onMounted } from 'vue'
import Aside from '@/components/Aside.vue'
import Header from '@/components/Header.vue'
import Tag from '@/components/Tag.vue'
import { useMenuStore } from '@/stores/modules/menu'
import { useEnumStore } from '@/stores/modules/enum'

const menuStore = useMenuStore()
const isCollapsed = computed(() => menuStore.isCollapsed)

onMounted(() => { useEnumStore().fetchEnums() })
</script>
<style scoped>
.admin-shell { background: var(--bg-page); }
.layout-sidebar { flex: none; box-shadow: 4px 0 24px rgba(12, 50, 32, .12); z-index: 2; }
.layout-right { flex: 1; min-width: 0; display: flex; flex-direction: column; }
.layout-header { height: var(--header-height); padding: 0 22px; background: #fff; border-bottom: 1px solid #e5eee7; }
.layout-tags { background: #fff; }
.layout-main { flex: 1; min-height: 0; overflow: auto; padding: 26px 20px; }
@media (max-width: 700px) { .layout-main { padding: 16px 10px; } .layout-header { padding: 0 8px; } }
</style>
