import { createRouter, createWebHistory } from 'vue-router'
import { isLoggedIn } from '../lib/auth'
import HomeView from '../views/HomeView.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: HomeView },
    { path: '/services', component: () => import('../views/ServicesView.vue') },
    { path: '/portfolio', component: () => import('../views/PortfolioView.vue') },
    { path: '/profile', component: () => import('../views/ProfileView.vue') },
    { path: '/contact', component: () => import('../views/ContactView.vue') },
    {
      path: '/lab',
      component: () => import('../layouts/LabLayout.vue'),
      children: [
        {
          path: 'login',
          name: 'lab-login',
          component: () => import('../views/lab/LabLoginView.vue'),
          meta: { guestOnly: true },
        },
        {
          path: '',
          name: 'lab-dashboard',
          component: () => import('../views/lab/LabDashboardView.vue'),
          meta: { requiresAuth: true },
        },
      ],
    },
  ],
  scrollBehavior: () => ({ top: 0 }),
})

router.beforeEach((to) => {
  if (to.meta.requiresAuth && !isLoggedIn()) {
    return '/lab/login'
  }
  if (to.meta.guestOnly && isLoggedIn()) {
    return '/lab'
  }
})

export default router
