<template>
  <el-dialog :model-value="visible" @update:model-value="$emit('update:visible', $event)"
    title="模拟支付（本地演示）" width="480px" center :close-on-click-modal="false">
    <p class="pay-notice">此操作仅更新订单状态，不会产生真实扣款。</p>
    <div class="pay-method-list">
      <div v-for="m in payMethods" :key="m.value"
        :class="['pay-method-card', { active: selectedPayMethod === m.value }]"
        @click="selectedPayMethod = m.value">
        <span class="pay-method-label">{{ m.label }}</span>
        <el-icon v-if="selectedPayMethod === m.value" class="pay-check" color="#21694f" :size="20">
          <CircleCheckFilled />
        </el-icon>
      </div>
    </div>
    <template #footer>
      <el-button @click="$emit('update:visible', false)">取消</el-button>
      <el-button color="#21694f" @click="confirmPay" :disabled="selectedPayMethod === null" :loading="paying">
        确认模拟支付
      </el-button>
    </template>
  </el-dialog>
</template>

<script setup>
import { ref, watch } from 'vue'
import { ElMessage } from 'element-plus'
import { CircleCheckFilled } from '@element-plus/icons-vue'
import { payOrder } from '@/api/order'

const props = defineProps({
  visible: Boolean,
  orderId: Number
})

const emit = defineEmits(['update:visible', 'paid'])

const selectedPayMethod = ref(null)
const paying = ref(false)

const payMethods = [
  { label: '支付宝演示', value: 2 },
  { label: '微信演示', value: 1 },
  { label: '银行卡演示', value: 3 }
]

watch(() => props.visible, (v) => {
  if (v) selectedPayMethod.value = null
})

const confirmPay = async () => {
  paying.value = true
  try {
    await payOrder(props.orderId, selectedPayMethod.value)
    ElMessage.success('模拟支付完成')
    emit('update:visible', false)
    emit('paid')
  } catch { ElMessage.error('支付失败') }
  finally { paying.value = false }
}
</script>

<style scoped>
.pay-notice { margin: 0 0 18px; padding: 10px 12px; border-radius: 8px; background: #eef7f1; color: #21694f; font-size: 13px; }
.pay-method-list { display: flex; gap: 16px; justify-content: center; }
.pay-method-card { display: flex; flex-direction: column; align-items: center; gap: 8px;
  padding: 12px; border: 2px solid #eee; border-radius: 10px; cursor: pointer;
  transition: all .15s; position: relative; width: 110px; }
.pay-method-card:hover { border-color: #21694f; }
.pay-method-card.active { border-color: #21694f; background: #eef7f1; }
.pay-method-label { min-height: 36px; display: flex; align-items: center; text-align: center; font-size: 13px; color: #333; }
.pay-check { position: absolute; top: 6px; right: 6px; }
</style>
