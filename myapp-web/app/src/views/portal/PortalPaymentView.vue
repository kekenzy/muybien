<template>
  <div class="max-w-2xl mx-auto px-6 py-10 space-y-8">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-xl font-bold">決済管理</h2>
        <p class="text-sm text-white/60 mt-1">お支払い方法（カード）の登録・変更・削除</p>
      </div>
      <button
        type="button"
        class="text-sm px-4 py-2 rounded-full bg-primary text-black font-medium hover:opacity-90 transition-opacity"
        @click="openAddDialog"
      >
        カードを追加
      </button>
    </div>

    <div v-if="errorMsg" class="bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-4 text-sm">
      {{ errorMsg }}
    </div>

    <div v-if="loading" class="text-center text-white/60 py-10 text-sm">読み込み中...</div>

    <div v-else-if="paymentMethods.length === 0" class="text-sm text-white/50">
      登録されているカードはありません。
    </div>

    <div v-else class="space-y-2">
      <div
        v-for="pm in paymentMethods"
        :key="pm.id"
        class="flex items-center justify-between rounded-lg border border-white/10 px-4 py-3"
      >
        <div>
          <div class="text-sm font-medium">
            {{ pm.brand.toUpperCase() }} •••• {{ pm.last4 }}
            <span v-if="pm.is_default" class="text-xs text-primary ml-2">デフォルト</span>
          </div>
          <div class="text-xs text-white/60 mt-0.5">
            有効期限 {{ String(pm.exp_month).padStart(2, '0') }}/{{ pm.exp_year }}
          </div>
        </div>
        <div class="flex items-center gap-3">
          <button
            v-if="!pm.is_default"
            type="button"
            class="text-xs text-white/70 hover:text-white transition-colors"
            @click="handleSetDefault(pm.id)"
          >
            デフォルトに設定
          </button>
          <button
            type="button"
            class="text-xs text-red-400/70 hover:text-red-400 transition-colors"
            @click="handleDelete(pm.id)"
          >
            削除
          </button>
        </div>
      </div>
    </div>

    <div
      v-if="showDialog"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 p-4"
      @click.self="closeDialog"
    >
      <div class="w-full max-w-md rounded-2xl border border-white/10 bg-[#0c1220] p-8 space-y-5">
        <div class="flex items-center justify-between">
          <h3 class="font-semibold text-base">カードを追加</h3>
          <button type="button" class="text-white/60 hover:text-white transition-colors" @click="closeDialog">
            ✕
          </button>
        </div>

        <div v-if="dialogErrorMsg" class="bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-3 text-sm">
          {{ dialogErrorMsg }}
        </div>

        <div v-if="dialogLoading" class="text-sm text-white/60">読み込み中...</div>
        <div v-show="!dialogLoading" ref="paymentElementRef" class="min-h-[200px]" />

        <button
          type="button"
          class="w-full bg-primary text-black py-3 rounded-xl text-sm font-medium hover:opacity-90 disabled:opacity-50 transition-opacity"
          :disabled="dialogLoading || submitting"
          @click="handleAddCard"
        >
          {{ submitting ? '登録中...' : 'カードを登録' }}
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { loadStripe, type Stripe, type StripeElements } from '@stripe/stripe-js'
import {
  createSetupIntent,
  deletePaymentMethod,
  fetchPaymentMethods,
  setDefaultPaymentMethod,
  type PaymentMethod,
} from '../../lib/portalApi'

const paymentMethods = ref<PaymentMethod[]>([])
const loading = ref(true)
const errorMsg = ref('')

const showDialog = ref(false)
const dialogLoading = ref(false)
const dialogErrorMsg = ref('')
const submitting = ref(false)
const paymentElementRef = ref<HTMLElement | null>(null)

let stripe: Stripe | null = null
let elements: StripeElements | null = null

async function loadPaymentMethods() {
  loading.value = true
  errorMsg.value = ''
  try {
    paymentMethods.value = await fetchPaymentMethods()
  } catch {
    errorMsg.value = 'カード情報の取得に失敗しました。'
  } finally {
    loading.value = false
  }
}

async function openAddDialog() {
  showDialog.value = true
  dialogLoading.value = true
  dialogErrorMsg.value = ''
  try {
    const publishableKey = import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY as string | undefined
    if (!publishableKey) {
      dialogErrorMsg.value = 'Stripeの設定が完了していません。'
      return
    }
    stripe = await loadStripe(publishableKey)
    const clientSecret = await createSetupIntent()
    if (!stripe) {
      dialogErrorMsg.value = 'Stripeの読み込みに失敗しました。'
      return
    }
    elements = stripe.elements({ clientSecret })
    const paymentElement = elements.create('payment')
    dialogLoading.value = false
    await nextTickMount(paymentElement)
  } catch {
    dialogErrorMsg.value = 'カード登録の準備に失敗しました。'
    dialogLoading.value = false
  }
}

async function nextTickMount(paymentElement: ReturnType<NonNullable<typeof elements>['create']>) {
  await new Promise((resolve) => setTimeout(resolve, 0))
  if (paymentElementRef.value) {
    paymentElement.mount(paymentElementRef.value)
  }
}

async function handleAddCard() {
  if (!stripe || !elements) return
  submitting.value = true
  dialogErrorMsg.value = ''
  try {
    const { error } = await stripe.confirmSetup({
      elements,
      redirect: 'if_required',
    })
    if (error) {
      dialogErrorMsg.value = error.message ?? 'カードの登録に失敗しました。'
      return
    }
    closeDialog()
    await loadPaymentMethods()
  } catch {
    dialogErrorMsg.value = 'カードの登録に失敗しました。'
  } finally {
    submitting.value = false
  }
}

function closeDialog() {
  showDialog.value = false
  elements = null
}

async function handleSetDefault(id: string) {
  try {
    await setDefaultPaymentMethod(id)
    await loadPaymentMethods()
  } catch {
    errorMsg.value = 'デフォルト設定に失敗しました。'
  }
}

async function handleDelete(id: string) {
  if (!confirm('このカードを削除しますか？')) return
  try {
    await deletePaymentMethod(id)
    await loadPaymentMethods()
  } catch {
    errorMsg.value = '削除に失敗しました。'
  }
}

onMounted(loadPaymentMethods)
</script>
