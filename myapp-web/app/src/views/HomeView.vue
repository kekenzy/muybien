<template>
  <div>
    <!-- Hero -->
    <section class="relative min-h-screen flex items-center overflow-hidden bg-[#080c14]">
      <!-- 背景グリッド -->
      <div class="absolute inset-0 bg-[linear-gradient(to_right,#ffffff08_1px,transparent_1px),linear-gradient(to_bottom,#ffffff08_1px,transparent_1px)] bg-[size:48px_48px]" />
      <!-- グロー -->
      <div class="absolute top-1/3 left-1/2 -translate-x-1/2 -translate-y-1/2 w-[600px] h-[600px] bg-blue-600/20 rounded-full blur-[120px] pointer-events-none" />

      <div class="relative max-w-5xl mx-auto px-4 sm:px-6 py-24 sm:py-32 w-full">
        <div class="inline-flex items-center gap-2 border border-white/10 bg-white/5 text-white/60 text-xs px-4 py-2 rounded-full mb-8 sm:mb-10 backdrop-blur">
          <span class="w-1.5 h-1.5 bg-green-400 rounded-full animate-pulse" />
          {{ texts.home_hero_badge || 'フリーランス受付中' }}
        </div>

        <h1 class="text-4xl sm:text-5xl md:text-8xl font-black text-white leading-[1.05] tracking-tight mb-6 sm:mb-8">
          {{ texts.home_hero_title_line1 || 'Build Faster.' }}<br>
          <span class="text-transparent bg-clip-text bg-gradient-to-r from-blue-400 to-cyan-300">
            {{ texts.home_hero_title_line2 || 'Ship Smarter.' }}
          </span>
        </h1>

        <p class="text-white/50 text-base sm:text-lg md:text-xl max-w-xl mb-10 sm:mb-12 leading-relaxed whitespace-pre-line">
          {{ texts.home_hero_subtitle || 'AI × Django × AWS で、あなたのプロダクトを最速で動かすエンジニア。' }}
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
        <div class="flex flex-wrap gap-6 sm:gap-10 mt-16 sm:mt-20 border-t border-white/10 pt-8 sm:pt-10">
          <div v-for="stat in stats" :key="stat.label">
            <div class="text-2xl sm:text-3xl font-black text-white">{{ stat.value }}</div>
            <div class="text-white/40 text-xs mt-1">{{ stat.label }}</div>
          </div>
        </div>
      </div>
    </section>

    <!-- お知らせ -->
    <section v-if="announcements.length > 0" class="py-24 px-6 bg-gray-50">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-16">
          <span class="text-xs font-semibold tracking-widest text-primary uppercase">News</span>
          <h2 class="text-3xl font-bold mt-2 text-gray-900">お知らせ</h2>
        </div>
        <div class="grid md:grid-cols-3 gap-6">
          <router-link
            v-for="item in announcements"
            :key="item.id"
            :to="`/news/${item.id}`"
            class="block p-6 rounded-2xl border border-gray-100 bg-white hover:border-primary/30 hover:shadow-md transition-all"
          >
            <img
              v-if="item.cover_image"
              :src="item.cover_image"
              :alt="item.title"
              class="w-full h-32 object-cover rounded-xl mb-4"
            />
            <div class="text-xs text-gray-400 mb-1">{{ formatDate(item.published_at) }}</div>
            <h3 class="font-semibold text-gray-900 leading-snug">{{ item.title }}</h3>
          </router-link>
        </div>
      </div>
    </section>

    <!-- Tech Stack -->
    <section class="py-24 px-6 bg-white">
      <div class="max-w-4xl mx-auto">
        <div class="text-center mb-16">
          <span class="text-xs font-semibold tracking-widest text-primary uppercase">Stack</span>
          <h2 class="text-3xl font-bold mt-2 text-gray-900">{{ texts.home_stack_heading || '使いこなす技術' }}</h2>
        </div>
        <div class="grid grid-cols-2 md:grid-cols-3 gap-4">
          <div
            v-for="skill in skills"
            :key="skill.title"
            class="group p-6 rounded-2xl border border-gray-100 hover:border-primary/30 hover:shadow-lg transition-all cursor-default"
          >
            <component :is="iconFor(skill.icon)" class="w-7 h-7 text-primary mb-4" />
            <div class="font-semibold text-gray-900 mb-1">{{ skill.title }}</div>
            <div class="text-xs text-gray-400 leading-relaxed">{{ skill.desc }}</div>
          </div>
        </div>
      </div>
    </section>

    <!-- CTA -->
    <section class="py-24 px-6 bg-[#080c14]">
      <div class="max-w-2xl mx-auto text-center">
        <h2 class="text-3xl sm:text-4xl md:text-5xl font-black text-white mb-6 leading-tight whitespace-pre-line">
          {{ texts.home_cta_title || '一緒に、速く\nつくりましょう。' }}
        </h2>
        <p class="text-white/40 mb-10">{{ texts.home_cta_subtitle || '初回相談は無料。まずは気軽に話しかけてください。' }}</p>
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
import { onMounted, ref } from 'vue'
import { ArrowRight, Bot, Server, Layers, Zap, Database, Cloud } from 'lucide-vue-next'
import { fetchPublicAnnouncements, fetchSiteContent, type Announcement } from '../lib/api'

const ICONS: Record<string, any> = { Bot, Server, Layers, Zap, Database, Cloud }
function iconFor(name: string) {
  return ICONS[name] ?? Bot
}

const texts = ref<Record<string, string>>({})
const stats = ref<{ value: string; label: string }[]>([])
const skills = ref<{ icon: string; title: string; desc: string }[]>([])
const announcements = ref<Announcement[]>([])

function formatDate(iso: string | null): string {
  if (!iso) return ''
  return new Date(iso).toLocaleDateString('ja-JP', { year: 'numeric', month: '2-digit', day: '2-digit' })
}

async function load() {
  try {
    const content = await fetchSiteContent()
    texts.value = content.texts
    stats.value = (content.items.home_stats ?? []).map((i) => i.data as any)
    skills.value = (content.items.home_skills ?? []).map((i) => i.data as any)
  } catch {
    // 取得失敗時はデフォルト文言のまま表示する
  }
  try {
    announcements.value = await fetchPublicAnnouncements(3)
  } catch {
    announcements.value = []
  }
}

onMounted(load)
</script>
