<template>
  <div class="max-w-5xl mx-auto px-6 py-10">
    <div class="mb-6">
      <h2 class="text-xl font-bold">パスワード変更</h2>
      <p class="text-sm text-white/60 mt-1">ログイン中のアカウントのパスワードを変更する</p>
    </div>

    <div class="max-w-sm">
      <div
        v-if="doneMsg"
        class="bg-green-500/10 border border-green-500/30 text-green-300 rounded-xl p-3 text-sm mb-4"
      >
        {{ doneMsg }}
      </div>

      <form class="space-y-4" @submit.prevent="submit">
        <div v-if="errorMsg" class="bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-3 text-sm">
          {{ errorMsg }}
        </div>

        <div>
          <label class="block text-xs text-white/70 mb-1.5">現在のパスワード</label>
          <input
            v-model="currentPassword"
            type="password"
            required
            autocomplete="current-password"
            class="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-sm outline-none focus:border-primary transition"
          />
        </div>
        <div>
          <label class="block text-xs text-white/70 mb-1.5">新しいパスワード（8文字以上）</label>
          <input
            v-model="newPassword"
            type="password"
            required
            minlength="8"
            autocomplete="new-password"
            class="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-sm outline-none focus:border-primary transition"
          />
        </div>
        <div>
          <label class="block text-xs text-white/70 mb-1.5">新しいパスワード（確認）</label>
          <input
            v-model="newPasswordConfirm"
            type="password"
            required
            minlength="8"
            autocomplete="new-password"
            class="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-sm outline-none focus:border-primary transition"
          />
        </div>
        <button
          type="submit"
          :disabled="loading"
          class="w-full bg-primary text-white py-3 rounded-xl text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
        >
          {{ loading ? '変更中...' : 'パスワードを変更' }}
        </button>
      </form>

      <p class="text-xs text-white/50 mt-6">
        現在のパスワードがわからない場合は、一度ログアウトしてログイン画面の「パスワードをお忘れの方」から再設定してください。
      </p>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { changePassword } from '../../lib/api'

const currentPassword = ref('')
const newPassword = ref('')
const newPasswordConfirm = ref('')
const loading = ref(false)
const errorMsg = ref('')
const doneMsg = ref('')

async function submit() {
  doneMsg.value = ''
  if (newPassword.value !== newPasswordConfirm.value) {
    errorMsg.value = '新しいパスワードが一致しません。'
    return
  }

  loading.value = true
  errorMsg.value = ''
  try {
    await changePassword(currentPassword.value, newPassword.value)
    doneMsg.value = 'パスワードを変更しました。次回から新しいパスワードでログインしてください。'
    currentPassword.value = ''
    newPassword.value = ''
    newPasswordConfirm.value = ''
  } catch (e: unknown) {
    const response =
      e && typeof e === 'object' && 'response' in e
        ? (e as { response?: { status?: number; data?: { detail?: string } } }).response
        : undefined
    errorMsg.value =
      response?.status === 429
        ? '試行回数が多すぎます。しばらく時間をおいてからお試しください。'
        : response?.data?.detail || 'パスワードの変更に失敗しました。'
  } finally {
    loading.value = false
  }
}
</script>
