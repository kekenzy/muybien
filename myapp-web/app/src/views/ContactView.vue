<template>
  <section class="py-24 px-6">
    <div class="max-w-lg mx-auto">
      <div class="text-center mb-12">
        <span class="text-xs font-semibold tracking-widest text-primary uppercase">Contact</span>
        <h1 class="text-3xl font-bold mt-2">お問い合わせ</h1>
        <p class="text-sm text-gray-500 mt-4 leading-relaxed">
          お仕事のご依頼・ご相談はこちらからどうぞ。<br>
          通常1〜2営業日以内にご返信いたします。
        </p>
      </div>

      <div v-if="success" class="bg-green-50 border border-green-200 text-green-700 rounded-2xl p-6 text-center text-sm">
        お問い合わせを受け付けました。<br>近日中にご連絡いたします。
      </div>

      <div v-if="errorMsg" class="bg-red-50 border border-red-200 text-red-600 rounded-2xl p-4 text-sm mb-6">
        {{ errorMsg }}
      </div>

      <form v-if="!success" @submit.prevent="submit" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">お名前 <span class="text-red-400">*</span></label>
          <input
            v-model="form.name"
            type="text"
            required
            placeholder="山田 太郎"
            class="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/10 transition"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">メールアドレス <span class="text-red-400">*</span></label>
          <input
            v-model="form.email"
            type="email"
            required
            placeholder="taro@example.com"
            class="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/10 transition"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">件名 <span class="text-red-400">*</span></label>
          <input
            v-model="form.subject"
            type="text"
            required
            placeholder="Django開発のご相談"
            class="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/10 transition"
          />
        </div>
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1.5">メッセージ <span class="text-red-400">*</span></label>
          <textarea
            v-model="form.message"
            required
            rows="6"
            placeholder="ご依頼内容をご記入ください"
            class="w-full px-4 py-3 rounded-xl border border-gray-200 text-sm outline-none focus:border-primary focus:ring-2 focus:ring-primary/10 transition resize-none"
          />
        </div>
        <label class="flex items-start gap-3 pt-2 text-sm text-gray-700 cursor-pointer">
          <input
            v-model="form.agree_privacy"
            type="checkbox"
            required
            class="mt-0.5 h-4 w-4 shrink-0 rounded border-gray-300 accent-primary"
          />
          <span>
            <router-link
              to="/privacy"
              target="_blank"
              class="text-primary underline underline-offset-2 hover:opacity-80"
            >プライバシーポリシー</router-link>に同意する <span class="text-red-400">*</span>
          </span>
        </label>
        <p class="text-xs text-gray-500">
          ご入力いただいた個人情報は、お問い合わせへの回答のために利用します。プライバシーポリシーに同意のうえ送信してください。
        </p>
        <button
          type="submit"
          :disabled="loading"
          class="w-full bg-primary text-white py-3.5 rounded-full text-sm font-medium hover:bg-primary/90 disabled:opacity-50 transition-colors mt-2"
        >
          {{ loading ? '送信中...' : '送信する' }}
        </button>
      </form>
    </div>
  </section>
</template>

<script setup lang="ts">
import { ref, reactive } from 'vue'
import axios from 'axios'

const loading = ref(false)
const success = ref(false)
const errorMsg = ref('')
const form = reactive({ name: '', email: '', subject: '', message: '', agree_privacy: false })

async function submit() {
  loading.value = true
  errorMsg.value = ''
  try {
    await axios.post('/v1/api/contact', form)
    success.value = true
  } catch {
    errorMsg.value = '送信に失敗しました。しばらく経ってから再度お試しください。'
  } finally {
    loading.value = false
  }
}
</script>
