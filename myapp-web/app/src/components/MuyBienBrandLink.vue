<template>
  <router-link
    to="/"
    class="shrink-0 font-bold text-lg tracking-tight text-white hover:opacity-90 transition-opacity"
    :aria-label="ariaLabel"
  >
    MuyBien
  </router-link>
</template>

<script setup lang="ts">
withDefaults(
  defineProps<{
    ariaLabel?: string
  }>(),
  {
    ariaLabel: 'MuyBien トップへ',
  },
)
</script>
