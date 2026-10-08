<template>
  <div class="flex items-center justify-center min-h-[calc(100vh-3.5rem)] px-6 py-12">
    <div class="w-full max-w-sm">
      <div class="text-center mb-8">
        <div class="text-4xl mb-3">🔬</div>
        <h1 class="text-2xl font-bold">永井のLab</h1>
        <p class="text-sm text-white/60 mt-2">
          {{ isReset ? '新しいパスワードを設定してください' : 'パスワードを設定してください' }}
        </p>
      </div>

      <div v-if="!uid || !token" class="bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-3 text-sm">
        リンクが正しくありません。{{ isReset ? '再設定メール' : '招待メール' }}のリンクを再度ご確認ください。
      </div>

      <template v-else-if="done">
        <div class="bg-green-500/10 border border-green-500/30 text-green-300 rounded-xl p-4 text-sm mb-6">
          {{
            isCustomer
              ? 'パスワードを設定しました。お客様ポータルからログインしてください。'
              : `パスワードを${isReset ? '再設定' : '設定'}しました。ログイン画面からログインしてください。`
          }}
        </div>
        <router-link
          :to="isCustomer ? '/portal/login' : '/lab/login'"
          class="block text-center bg-primary text-white py-3 rounded-xl text-sm font-medium hover:bg-primary/90 transition-colors"
        >
          {{ isCustomer ? 'ポータルログインへ' : 'ログイン画面へ' }}
        </router-link>
      </template>

      <form v-else class="space-y-4" @submit.prevent="submit">
        <div v-if="errorMsg" class="bg-red-500/10 border border-red-500/30 text-red-300 rounded-xl p-3 text-sm">
          {{ errorMsg }}
          <router-link v-if="isReset" to="/lab/forgot-password" class="block mt-2 underline hover:text-red-200">
            再設定メールをもう一度送る
          </router-link>
        </div>

        <div>
          <label class="block text-xs text-white/70 mb-1.5">新しいパスワード（8文字以上）</label>
          <input
            v-model="password"
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
            v-model="passwordConfirm"
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
          {{ loading ? '設定中...' : 'パスワードを設定' }}
        </button>
      </form>

      <router-link to="/" class="block text-center text-xs text-white/50 hover:text-white/70 mt-8 transition-colors">
        ← サイトに戻る
      </router-link>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue'
import { useRoute } from 'vue-router'
import { confirmPasswordReset, setPassword } from '../../lib/api'

// invite: 招待メールからの初回設定 / reset: パスワードを忘れたときの再設定
const props = withDefaults(defineProps<{ mode?: 'invite' | 'reset' }>(), { mode: 'invite' })
const isReset = props.mode === 'reset'

const route = useRoute()
const uid = String(route.query.uid ?? '')
const token = String(route.query.token ?? '')

const password = ref('')
const passwordConfirm = ref('')
const loading = ref(false)
const errorMsg = ref('')
const done = ref(false)
const isCustomer = ref(false)

async function submit() {
  if (password.value !== passwordConfirm.value) {
    errorMsg.value = 'パスワードが一致しません。'
    return
  }

  loading.value = true
  errorMsg.value = ''
  try {
    if (isReset) {
      await confirmPasswordReset(uid, token, password.value)
    } else {
      const result = await setPassword(uid, token, password.value)
      isCustomer.value = result.is_customer
    }
    done.value = true
  } catch (e: unknown) {
    const detail =
      e && typeof e === 'object' && 'response' in e
        ? (e as { response?: { data?: { detail?: string } } }).response?.data?.detail
        : undefined
    errorMsg.value =
      detail || 'パスワードの設定に失敗しました。リンクの有効期限が切れている可能性があります。'
  } finally {
    loading.value = false
  }
}
</script>
