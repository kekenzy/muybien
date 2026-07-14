import { createRouter, createWebHistory } from 'vue-router'
import { isLoggedIn } from '../lib/auth'
import { canRead, type MenuKey } from '../lib/permissions'
import HomeView from '../views/HomeView.vue'

const LAB_MENU_ROUTES: { menuKey: MenuKey; path: string }[] = [
  { menuKey: 'contacts', path: '/lab' },
  { menuKey: 'customers', path: '/lab/customers' },
  { menuKey: 'tasks', path: '/lab/tasks' },
  { menuKey: 'diary', path: '/lab/diary' },
  { menuKey: 'users', path: '/lab/users' },
  { menuKey: 'roles', path: '/lab/roles' },
]

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
          path: 'set-password',
          name: 'lab-set-password',
          component: () => import('../views/lab/LabSetPasswordView.vue'),
        },
        {
          path: '',
          name: 'lab-dashboard',
          component: () => import('../views/lab/LabDashboardView.vue'),
          meta: { requiresAuth: true, menuKey: 'contacts' },
        },
        {
          path: 'customers',
          name: 'lab-customers',
          component: () => import('../views/lab/LabCustomerView.vue'),
          meta: { requiresAuth: true, menuKey: 'customers' },
        },
        {
          path: 'tasks',
          name: 'lab-tasks',
          component: () => import('../views/lab/LabTaskView.vue'),
          meta: { requiresAuth: true, menuKey: 'tasks' },
        },
        {
          path: 'diary',
          name: 'lab-diary',
          component: () => import('../views/lab/LabDiaryView.vue'),
          meta: { requiresAuth: true, menuKey: 'diary' },
        },
        {
          path: 'users',
          name: 'lab-users',
          component: () => import('../views/lab/LabUserView.vue'),
          meta: { requiresAuth: true, menuKey: 'users' },
        },
        {
          path: 'roles',
          name: 'lab-roles',
          component: () => import('../views/lab/LabRoleView.vue'),
          meta: { requiresAuth: true, menuKey: 'roles' },
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

  const menuKey = to.meta.menuKey as MenuKey | undefined
  if (menuKey && !canRead(menuKey)) {
    const fallback = LAB_MENU_ROUTES.find((m) => m.menuKey !== menuKey && canRead(m.menuKey))
    if (fallback) return fallback.path
    return false
  }
})

export default router
