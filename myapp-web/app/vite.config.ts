import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import path from 'path'

export default defineConfig({
  plugins: [vue(), tailwindcss()],
  resolve: {
    alias: { '@': path.resolve(__dirname, './src') },
  },
  server: {
    host: '0.0.0.0',
    port: 5173,
    proxy: {
      '/v1/api': { target: 'http://myapp-api:8000', changeOrigin: true },
      '/media': { target: 'http://myapp-api:8000', changeOrigin: true },
    },
  },
})
