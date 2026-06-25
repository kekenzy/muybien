import { createRouter, createWebHistory } from 'vue-router'
import HomeView from '../views/HomeView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: HomeView },
    { path: '/services', component: () => import('../views/ServicesView.vue') },
    { path: '/portfolio', component: () => import('../views/PortfolioView.vue') },
    { path: '/profile', component: () => import('../views/ProfileView.vue') },
    { path: '/contact', component: () => import('../views/ContactView.vue') },
  ],
  scrollBehavior: () => ({ top: 0 }),
})

export default router
