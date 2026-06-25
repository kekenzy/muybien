<template>
  <div class="min-h-screen flex flex-col bg-white text-gray-900">
    <!-- Header -->
    <header class="sticky top-0 z-50 border-b border-white/10 bg-[#080c14]/80 backdrop-blur">
      <div class="max-w-5xl mx-auto px-6 h-16 flex items-center justify-between">
        <router-link to="/" class="font-bold text-xl tracking-tight text-white">
          MuyBien
        </router-link>
        <nav class="hidden md:flex items-center gap-8">
          <router-link
            v-for="item in navItems"
            :key="item.to"
            :to="item.to"
            class="text-sm text-white/60 hover:text-white transition-colors"
            active-class="text-white font-medium"
          >
            {{ item.label }}
          </router-link>
          <router-link
            to="/contact"
            class="text-sm border border-white/20 text-white/80 px-4 py-2 rounded-full hover:border-white/50 hover:text-white transition-colors"
          >
            お問い合わせ
          </router-link>
        </nav>
      </div>
    </header>

    <main class="flex-1">
      <router-view />
    </main>

    <footer class="border-t border-white/10 bg-[#080c14] py-8 text-center text-sm text-white/30">
      © 2024 永井謙史 All rights reserved.
    </footer>
  </div>
</template>

<script setup lang="ts">
const navItems = [
  { label: 'ホーム', to: '/' },
  { label: 'プロフィール', to: '/profile' },
  { label: 'サービス', to: '/services' },
  { label: 'ポートフォリオ', to: '/portfolio' },
]
</script>
