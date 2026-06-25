<template>
  <div>
    <!-- Hero -->
    <section class="relative min-h-screen flex items-center overflow-hidden bg-[#080c14]">
      <!-- 背景グリッド -->
      <div class="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:48px_48px]" />
      <!-- グロー -->
      <div class="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-blue-600/20 rounded-full blur-[120px] pointer-events-none" />

      <div class="relative max-w-5xl mx-auto px-6 py-32 w-full">
        <div class="inline-flex items-center gap-2 border border-white/10 bg-white/5 text-white/60 text-xs px-4 py-2 rounded-full mb-10 backdrop-blur">
          <span class="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" />
          フリーランス受付中
        </div>

        <h1 class="text-5xl md:text-8xl font-black text-white leading-[1.05] tracking-tight mb-8">
          Build Faster.<br>
          <span class="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-cyan-300">
            Ship Smarter.
          </span>
        </h1>

        <p class="text-white/50 text-lg md:text-xl max-w-xl mb-12 leading-relaxed">
          AI × Django × AWS で、あなたのプロダクトを<br class="hidden md:block">
          最速で動かすエンジニア。
        </p>

        <div class="flex flex-wrap gap-4">
          <router-link
            to="/services"
            class="group flex items-center gap-2 bg-white text-gray-900 px-7 py-3.5 rounded-full text-sm font-semibold hover:bg-gray-100 transition-colors"
          >
            サービスを見る
            <ArrowRight class="w-4 h-4 group-hover:translate-x-0.5 transition-transform" />
          </router-link>
          <router-link
            to="/contact"
            class="flex items-center gap-2 border border-white/20 text-white/80 px-7 py-3.5 rounded-full text-sm font-medium hover:border-white/40 hover:text-white transition-colors"
          >
            無料相談
          </router-link>
        </div>

        <!-- Stats -->
        <div class="flex flex-wrap gap-10 mt-20 border-t border-white/10 pt-10">
          <div v-for="stat in stats" :key="stat.label">
            <div class="text-3xl font-black text-white">{{ stat.value }}</div>
            <div class="text-white/40 text-xs mt-1">{{ stat.label }}</div>
          </div>
        </div>
      </div>
    </section>

    <!-- Tech Stack -->
    <section class="py-24 px-6 bg-white">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-16">
          <span class="text-xs font-semibold tracking-widest text-primary uppercase">Stack</span>
          <h2 class="text-3xl font-bold mt-2 text-gray-900">使いこなす技術</h2>
        </div>
        <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div
            v-for="skill in skills"
            :key="skill.title"
            class="group p-6 rounded-2xl border border-gray-100 hover:border-primary/30 hover:shadow-lg transition-all cursor-default"
          >
            <component :is="skill.icon" class="w-7 h-7 text-primary mb-4" />
            <div class="font-semibold text-gray-900 mb-1">{{ skill.title }}</div>
            <div class="text-xs text-gray-400 leading-relaxed">{{ skill.desc }}</div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section class="py-24 px-6 bg-[#080c14]">
      <div class="max-w-2xl mx-auto text-center">
        <h2 class="text-4xl md:text-5xl font-black text-white mb-6 leading-tight">
          一緒に、速く<br>つくりましょう。
        </h2>
        <p class="text-white/40 mb-10">初回相談は無料。まずは気軽に話しかけてください。</p>
        <router-link
          to="/contact"
          class="inline-flex items-center gap-2 bg-white text-gray-900 px-8 py-4 rounded-full font-semibold text-sm hover:bg-gray-100 transition-colors"
        >
          お問い合わせ <ArrowRight class="w-4 h-4" />
        </router-link>
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import { Bot, Server, Layers, Zap, Database, Cloud } from 'lucide-vue-next'
import { ArrowRight } from 'lucide-vue-next'

const stats = [
  { value: '3×', label: '平均開発スピード向上' },
  { value: '10+', label: '納品プロジェクト' },
  { value: '48h', label: '最速納期' },
]

const skills = [
  { icon: Bot, title: 'Claude / GPT-4', desc: 'プロンプト設計・RAG・自動化' },
  { icon: Server, title: 'Django REST', desc: 'API設計・認証・パフォーマンス' },
  { icon: Layers, title: 'Vue3 + Tailwind', desc: 'SPA・TypeScript・shadcn-vue' },
  { icon: Cloud, title: 'AWS Lightsail', desc: 'デプロイ・Nginx・SSL・SES' },
  { icon: Database, title: 'PostgreSQL', desc: 'スキーマ設計・最適化' },
  { icon: Zap, title: 'Cursor IDE', desc: 'AI駆動開発で爆速実装' },
]
</script>
