<template>
  <section class="py-24 px-6">
    <div class="max-w-4xl mx-auto">
      <div class="text-center mb-16">
        <span class="text-xs font-semibold tracking-widest text-primary uppercase">Services</span>
        <h1 class="text-3xl font-bold mt-2">提供サービス</h1>
      </div>

      <div class="grid md:grid-cols-3 gap-6">
        <div
          v-for="service in services"
          :key="service.title"
          class="flex flex-col p-8 rounded-2xl border border-gray-100 hover:border-primary/30 hover:shadow-md transition-all"
        >
          <span class="text-xs font-semibold text-primary bg-blue-50 px-3 py-1 rounded-full w-fit mb-6">
            {{ service.category }}
          </span>
          <h2 class="font-semibold text-lg mb-1">{{ service.title }}</h2>
          <div class="text-3xl font-bold text-primary mb-6">
            ¥{{ service.price.toLocaleString() }}<span class="text-base font-normal text-gray-400">〜</span>
          </div>
          <ul class="space-y-2 text-sm text-gray-500 flex-1">
            <li v-for="item in service.includes" :key="item" class="flex items-start gap-2">
              <span class="text-primary mt-0.5">✓</span>
              {{ item }}
            </li>
          </ul>
          <router-link
            to="/contact"
            class="mt-8 block text-center border border-primary text-primary px-6 py-2.5 rounded-full text-sm font-medium hover:bg-primary hover:text-white transition-colors"
          >
            相談する
          </router-link>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
const services = [
  {
    category: 'Web開発相談',
    title: 'Web開発相談',
    price: 10000,
    includes: [
      'オンライン30分 × 1回',
      'アーキテクチャレビュー',
      'デプロイ・インフラ相談',
      'コードレビュー対応',
    ],
  },
  {
    category: 'AI活用',
    title: 'AIプロンプト設計パッケージ',
    price: 10000,
    includes: [
      'ユースケースヒアリング（60分）',
      'プロンプトテンプレート作成',
      'Claude / GPT-4 対応',
      '1週間サポート付き',
    ],
  },
  {
    category: 'レッスン',
    title: 'Claude / Cursor 活用レッスン',
    price: 15000,
    includes: [
      'オンライン60分 × 1回',
      '開発フロー効率化の実演',
      'カスタム設定のレビュー',
      'アーカイブ動画提供',
    ],
  },
]
</script>
