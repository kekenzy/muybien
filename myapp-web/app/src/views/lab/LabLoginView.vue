<template>
  <div class="flex items-center justify-center min-h-[calc(100vh-3.5rem)] px-6 py-12">
    <div class="w-full max-w-sm">
      <div class="text-center mb-8">
        <div class="text-4xl mb-3">🔬</div>
        <h1 class="text-2xl font-bold">永井のLab</h1>
        <p class="text-sm text-white/40 mt-2">管理者ログイン</p>
      </div>

      <div v-if="errorMsg" class="bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-3 text-sm mb-4">
        {{ errorMsg }}
      </div>

      <form class="space-y-4" @submit.prevent="submit">
        <div>
          <label class="block text-xs text-white/50 mb-1.5">ユーザー名</label>
          <input
            v-model="username"
            type="text"
            required
            autocomplete="username"
            class="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-sm outline-none focus:border-primary transition"
          />
        </div>
        <div>
          <label class="block text-xs text-white/50 mb-1.5">パスワード</label>
          <input
            v-model="password"
            type="password"
            required
            autocomplete="current-password"
            class="w-full px-4 py-3 rounded-xl bg-white/5 border border-white/10 text-sm outline-none focus:border-primary transition"
          />
        </div>
        <button
          type="submit"
          :disabled="loading"
          class="w-full bg-primary text-white py-3 rounded-xl text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors"
        >
          {{ loading ? 'ログイン中...' : 'ログイン' }}
        </button>
      </form>

      <router-link to="/" class="block text-center text-xs text-white/30 hover:text-white/50 mt-8 transition-colors">
        ← サイトに戻る
      </router-link>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { fetchMe, login } from '../../lib/api'

const router = useRouter()
const username = ref('')
const password = ref('')
const loading = ref(false)
const errorMsg = ref('')

async function submit() {
  loading.value = true
  errorMsg.value = ''
  try {
    await login(username.value, password.value)
    const me = await fetchMe()
    sessionStorage.setItem('lab_username', me.username)
    router.push('/lab')
  } catch {
    errorMsg.value = 'ログインに失敗しました。ユーザー名とパスワードを確認してください。'
  } finally {
    loading.value = false
  }
}
</script>
