<template>
  <section class="py-24 px-6">
    <div class="max-w-4xl mx-auto">
      <div class="text-center mb-16">
        <span class="text-xs font-semibold tracking-widest text-primary uppercase">Portfolio</span>
        <h1 class="text-3xl font-bold mt-2">{{ heading }}</h1>
      </div>

      <div class="grid md:grid-cols-2 gap-6">
        <div
          v-for="work in works"
          :key="work.title"
          class="p-8 rounded-2xl border border-gray-100 hover:border-primary/30 hover:shadow-md transition-all"
        >
          <component :is="iconFor(work.icon)" class="w-7 h-7 text-primary mb-4" />
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
          <a
            v-if="work.url"
            :href="work.url"
            target="_blank"
            rel="noopener noreferrer"
            class="mt-4 inline-flex items-center gap-1 text-xs text-primary hover:underline"
          >
            サイトを見る →
          </a>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { Building2, CalendarCheck, BotMessageSquare, Sprout } from 'lucide-vue-next'
import { fetchSiteContent } from '../lib/api'

const ICONS: Record<string, any> = { Building2, CalendarCheck, BotMessageSquare, Sprout }
function iconFor(name: string) {
  return ICONS[name] ?? Building2
}

interface Work {
  icon: string
  title: string
  period: string
  desc: string
  tags: string[]
  url?: string
}

const heading = ref('実績・ポートフォリオ')
const works = ref<Work[]>([])

async function load() {
  try {
    const content = await fetchSiteContent()
    heading.value = content.texts.portfolio_heading || heading.value
    works.value = (content.items.portfolio ?? []).map((i) => i.data as unknown as Work)
  } catch {
    // 取得失敗時は空表示のまま
  }
}

onMounted(load)
</script>
