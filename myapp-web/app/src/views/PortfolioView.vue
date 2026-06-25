<template>
  <section class="py-24 px-6">
    <div class="max-w-4xl mx-auto">
      <div class="text-center mb-16">
        <span class="text-xs font-semibold tracking-widest text-primary uppercase">Portfolio</span>
        <h1 class="text-3xl font-bold mt-2">実績・ポートフォリオ</h1>
      </div>

      <div class="grid md:grid-cols-2 gap-6">
        <div
          v-for="work in works"
          :key="work.title"
          class="p-8 rounded-2xl border border-gray-100 hover:border-primary/30 hover:shadow-md transition-all"
        >
          <component :is="work.icon" class="w-7 h-7 text-primary mb-4" />
          <div class="text-xs text-gray-400 mb-1">{{ work.period }}</div>
          <h2 class="font-semibold text-lg mb-3">{{ work.title }}</h2>
          <p class="text-sm text-gray-500 leading-relaxed mb-5">{{ work.desc }}</p>
          <div class="flex flex-wrap gap-2">
            <span
              v-for="tag in work.tags"
              :key="tag"
              class="text-xs bg-blue-50 text-primary px-2.5 py-1 rounded-full"
            >
              {{ tag }}
            </span>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { Building2, CalendarCheck, BotMessageSquare, Sprout } from 'lucide-vue-next'

const works = [
  {
    icon: Building2,
    title: '社内業務管理プラットフォーム',
    period: '2023〜2024',
    desc: '人事・営業・プロジェクト管理を統合したSaaS型Webアプリ。Claude活用で開発工数を40%削減。',
    tags: ['Django', 'Vue3', 'AWS', 'PostgreSQL', 'Claude API'],
  },
  {
    icon: CalendarCheck,
    title: '予約・決済システム',
    period: '2023',
    desc: 'Django + Square API連携による予約管理。SMS通知・キャンセル自動処理・売上レポートを実装。',
    tags: ['Django', 'Square API', 'AWS SES', 'Lightsail'],
  },
  {
    icon: BotMessageSquare,
    title: 'AIチャットボット基盤',
    period: '2024',
    desc: 'Claude API + RAGを活用した社内ナレッジQ&Aシステム。SSEによるストリーミング対応。',
    tags: ['Claude API', 'RAG', 'Django', 'Vue3', 'SSE'],
  },
  {
    icon: Sprout,
    title: '農業IoTデータ可視化',
    period: '2022〜2023',
    desc: 'Raspberry Pi センサーデータのリアルタイム収集・可視化ダッシュボード。',
    tags: ['Python', 'Raspberry Pi', 'Django', 'Chart.js'],
  },
]
</script>
