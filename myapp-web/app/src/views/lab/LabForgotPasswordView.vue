<template>
  <div class="flex items-center justify-center min-h-[calc(100vh-3.5rem)] px-6 py-12">
    <div class="w-full max-w-sm">
      <div class="text-center mb-8">
        <div class="text-4xl mb-3">🔬</div>
        <h1 class="text-2xl font-bold">永井のLab</h1>
        <p class="text-sm text-white/60 mt-2">パスワードの再設定</p>
      </div>

      <template v-if="sentMsg">
        <div class="bg-green-500/10 border border-green-500/30 text-green-300 rounded-xl p-4 text-sm mb-6">
          {{ sentMsg }}
          <p class="mt-2 text-green-300/80">メールが届かない場合は、迷惑メールフォルダもご確認ください。</p>
        </div>
      </template>

      <form v-else class="space-y-4" @submit.prevent="submit">
        <p class="text-sm text-white/70">
          登録しているメールアドレスを入力してください。パスワード再設定用のリンクをお送りします。
        </p>

        <div v-if="errorMsg" class="bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-3 text-sm">
          {{ errorMsg }}
        </div>

        <div>
          <label class="block text-xs text-white/70 mb-1.5">メールアドレス</label>
          <input
            v-model="email"
            type="email"
            required
            autocomplete="email"
            class="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-sm outline-none focus:border-primary transition"
          />
        </div>
        <button
          type="submit"
          :disabled="loading"
          class="w-full bg-primary text-white py-3 rounded-xl text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
        >
          {{ loading ? '送信中...' : '再設定メールを送信' }}
        </button>
      </form>

      <router-link
        to="/lab/login"
        class="block text-center text-xs text-white/50 hover:text-white/70 mt-8 transition-colors"
      >
        ← ログイン画面に戻る
      </router-link>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { requestPasswordReset } from '../../lib/api'

const email = ref('')
const loading = ref(false)
const errorMsg = ref('')
const sentMsg = ref('')

async function submit() {
  loading.value = true
  errorMsg.value = ''
  try {
    const result = await requestPasswordReset(email.value)
    sentMsg.value = result.detail
  } catch (e: unknown) {
    const response =
      e && typeof e === 'object' && 'response' in e
        ? (e as { response?: { status?: number; data?: { detail?: string } } }).response
        : undefined
    errorMsg.value =
      response?.status === 429
        ? '短時間に送信が続いたため、しばらく時間をおいてからお試しください。'
        : response?.data?.detail || '送信に失敗しました。時間をおいて再度お試しください。'
  } finally {
    loading.value = false
  }
}
</script>
