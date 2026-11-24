import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { clearTokens, isLoggedIn } from '../lib/auth'
import { isPortalLoggedIn } from '../lib/portalAuth'
import { canRead, clearPermissions, type MenuKey } from '../lib/permissions'
import { LAB_ONLY } from '../lib/siteMode'

const LAB_MENU_ROUTES: { menuKey: MenuKey; path: string }[] = [
  { menuKey: 'contacts', path: '/lab' },
  { menuKey: 'customers', path: '/lab/customers' },
  { menuKey: 'tasks', path: '/lab/tasks' },
  { menuKey: 'diary', path: '/lab/diary' },
  { menuKey: 'memo', path: '/lab/memos' },
  { menuKey: 'daily', path: '/lab/daily' },
  { menuKey: 'reservations', path: '/lab/reservations' },
  { menuKey: 'users', path: '/lab/users' },
  { menuKey: 'roles', path: '/lab/roles' },
  { menuKey: 'announcements', path: '/lab/announcements' },
  { menuKey: 'site_content', path: '/lab/content' },
]

const publicRoutes: RouteRecordRaw[] = [
  { path: '/', component: () => import('../views/HomeView.vue') },
  { path: '/services', component: () => import('../views/ServicesView.vue') },
  { path: '/portfolio', component: () => import('../views/PortfolioView.vue') },
  { path: '/profile', component: () => import('../views/ProfileView.vue') },
  { path: '/contact', component: () => import('../views/ContactView.vue') },
  { path: '/news/:id', component: () => import('../views/AnnouncementDetailView.vue') },
]

const portalRoutes: RouteRecordRaw[] = [
  {
    path: '/portal',
    component: () => import('../layouts/PortalLayout.vue'),
    children: [
      {
        path: 'login',
        name: 'portal-login',
        component: () => import('../views/portal/PortalLoginView.vue'),
        meta: { portalGuestOnly: true },
      },
      {
        path: 'set-password',
        name: 'portal-set-password',
        component: () => import('../views/portal/PortalSetPasswordView.vue'),
      },
      {
        path: '',
        name: 'portal-root',
        redirect: '/portal/reservations',
      },
      {
        path: 'reservations',
        name: 'portal-reservations',
        component: () => import('../views/portal/PortalReservationView.vue'),
        meta: { requiresPortalAuth: true },
      },
      {
        path: 'payment',
        name: 'portal-payment',
        component: () => import('../views/portal/PortalPaymentView.vue'),
        meta: { requiresPortalAuth: true },
      },
    ],
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes: [
    // 公開ページ（LAB_ONLY の間は出さない。lib/siteMode.ts）
    ...(LAB_ONLY ? [] : publicRoutes),
    { path: '/privacy', component: () => import('../views/PrivacyView.vue') },
    // 静的LP（public/picsco）。Viteは /picsco/ をSPAに落とすため index.html へハード遷移する
    {
      path: '/picsco/:pathMatch(.*)*',
      beforeEnter: () => {
        window.location.replace('/picsco/index.html')
        return false
      },
      component: { render: () => null },
    },
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
          path: 'forgot-password',
          name: 'lab-forgot-password',
          component: () => import('../views/lab/LabForgotPasswordView.vue'),
          meta: { guestOnly: true },
        },
        {
          path: 'reset-password',
          name: 'lab-reset-password',
          component: () => import('../views/lab/LabSetPasswordView.vue'),
          props: { mode: 'reset' },
        },
        {
          path: 'password',
          name: 'lab-password',
          component: () => import('../views/lab/LabPasswordView.vue'),
          meta: { requiresAuth: true },
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
          path: 'memos',
          name: 'lab-memos',
          component: () => import('../views/lab/LabMemoView.vue'),
          meta: { requiresAuth: true, menuKey: 'memo' },
        },
        {
          path: 'daily',
          name: 'lab-daily',
          component: () => import('../views/lab/LabDailyView.vue'),
          meta: { requiresAuth: true, menuKey: 'daily' },
        },
        {
          path: 'reservations',
          name: 'lab-reservations',
          component: () => import('../views/lab/LabReservationView.vue'),
          meta: { requiresAuth: true, menuKey: 'reservations' },
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
        {
          path: 'announcements',
          name: 'lab-announcements',
          component: () => import('../views/lab/LabAnnouncementView.vue'),
          meta: { requiresAuth: true, menuKey: 'announcements' },
        },
        {
          path: 'content',
          name: 'lab-content',
          component: () => import('../views/lab/LabContentView.vue'),
          meta: { requiresAuth: true, menuKey: 'site_content' },
        },
      ],
    },
    // 顧客ポータル（LAB_ONLY の間は出さない）
    ...(LAB_ONLY ? [] : portalRoutes),
    // LAB_ONLY の間、上にない URL（/・/profile・/portal など）は Lab へ移す。
    // 未ログインなら beforeEach が /lab/login へ移す
    ...(LAB_ONLY ? [{ path: '/:pathMatch(.*)*', redirect: '/lab' }] : []),
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
    // 閲覧可能なメニューが一つもない（顧客招待などで作られた無権限アカウント等）場合、
    // ここで false を返すとURLとルーターの状態が食い違ったまま固まってしまうため、
    // セッションを破棄してログイン画面に戻す
    clearTokens()
    clearPermissions()
    return '/lab/login'
  }

  if (to.meta.requiresPortalAuth && !isPortalLoggedIn()) {
    return '/portal/login'
  }
  if (to.meta.portalGuestOnly && isPortalLoggedIn()) {
    return '/portal/reservations'
  }
})

export default router
