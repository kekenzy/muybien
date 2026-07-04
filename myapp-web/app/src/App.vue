<template>
  <div v-if="isLabRoute" class="min-h-screen">
    <router-view />
  </div>
  <div v-else class="min-h-screen flex flex-col bg-white text-gray-900">
    <!-- Header -->
    <header class="sticky top-0 z-50 border-b border-white/10 bg-[#080c14]/80 backdrop-blur">
      <div class="max-w-5xl mx-auto px-4 sm:px-6 h-16 flex items-center justify-between">
        <router-link to="/" class="font-bold text-xl tracking-tight text-white" @click="closeMenu">
          MuyBien
        </router-link>

        <!-- Desktop nav -->
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

        <!-- Mobile menu button -->
        <button
          type="button"
          class="md:hidden flex items-center justify-center w-10 h-10 rounded-lg text-white/80 hover:text-white hover:bg-white/10 transition-colors"
          :aria-expanded="menuOpen"
          aria-controls="mobile-nav"
          aria-label="メニュー"
          @click="menuOpen = !menuOpen"
        >
          <Menu v-if="!menuOpen" class="w-6 h-6" />
          <X v-else class="w-6 h-6" />
        </button>
      </div>

      <!-- Mobile nav -->
      <Transition
        enter-active-class="transition duration-200 ease-out"
        enter-from-class="opacity-0 -translate-y-2"
        enter-to-class="opacity-100 translate-y-0"
        leave-active-class="transition duration-150 ease-in"
        leave-from-class="opacity-100 translate-y-0"
        leave-to-class="opacity-0 -translate-y-2"
      >
        <nav
          v-if="menuOpen"
          id="mobile-nav"
          class="md:hidden border-t border-white/10 bg-[#080c14] px-4 py-4"
        >
          <div class="flex flex-col gap-1">
            <router-link
              v-for="item in navItems"
              :key="item.to"
              :to="item.to"
              class="px-4 py-3 rounded-xl text-base text-white/70 hover:text-white hover:bg-white/5 transition-colors"
              active-class="!text-white font-medium bg-white/10"
              @click="closeMenu"
            >
              {{ item.label }}
            </router-link>
            <router-link
              to="/contact"
              class="mt-2 text-center border border-white/20 text-white px-4 py-3 rounded-full text-sm font-medium hover:border-white/50 transition-colors"
              @click="closeMenu"
            >
              お問い合わせ
            </router-link>
          </div>
        </nav>
      </Transition>
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
import { computed, ref, watch } from 'vue'
import { useRoute } from 'vue-router'
import { Menu, X } from 'lucide-vue-next'

const route = useRoute()
const isLabRoute = computed(() => route.path.startsWith('/lab'))
const menuOpen = ref(false)

const navItems = [
  { label: 'ホーム', to: '/' },
  { label: 'プロフィール', to: '/profile' },
  { label: 'サービス', to: '/services' },
  { label: 'ポートフォリオ', to: '/portfolio' },
]

function closeMenu() {
  menuOpen.value = false
}

watch(() => route.path, closeMenu)
watch(menuOpen, (open) => {
  document.body.style.overflow = open ? 'hidden' : ''
})
</script>
