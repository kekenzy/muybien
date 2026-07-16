import axios from 'axios'
import { clearTokens, getAccessToken, getRefreshToken, setTokens } from './portalAuth'

const portalApi = axios.create({
  baseURL: '/v1/api',
})

portalApi.interceptors.request.use((config) => {
  const token = getAccessToken()
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

portalApi.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error.config
    if (error.response?.status !== 401 || original._retry) {
      return Promise.reject(error)
    }

    const refresh = getRefreshToken()
    if (!refresh) {
      clearTokens()
      return Promise.reject(error)
    }

    original._retry = true
    try {
      const { data } = await axios.post('/v1/api/auth/refresh', { refresh })
      setTokens(data.access, refresh)
      original.headers.Authorization = `Bearer ${data.access}`
      return portalApi(original)
    } catch {
      clearTokens()
      window.location.href = '/portal/login'
      return Promise.reject(error)
    }
  },
)

export default portalApi

export interface LoginResponse {
  access: string
  refresh: string
}

export interface PortalMeResponse {
  username: string
  email: string
  is_staff: boolean
  is_superuser: boolean
  is_customer: boolean
  permissions: Record<string, number>
}

export async function portalLogin(username: string, password: string): Promise<LoginResponse> {
  const { data } = await portalApi.post<LoginResponse>('/auth/login', { username, password })
  setTokens(data.access, data.refresh)
  return data
}

export async function fetchPortalMe(): Promise<PortalMeResponse> {
  const { data } = await portalApi.get<PortalMeResponse>('/auth/me')
  return data
}

export function portalLogout(): void {
  clearTokens()
}

export interface AvailabilitySlot {
  start_at: string
  end_at: string
}

export async function fetchAvailability(from: string, to: string): Promise<AvailabilitySlot[]> {
  const { data } = await portalApi.get<AvailabilitySlot[]>('/portal/availability', { params: { from, to } })
  return data
}

export type AppointmentStatus = 'confirmed' | 'cancelled'

export interface Appointment {
  id: number
  start_at: string
  end_at: string
  status: AppointmentStatus
  note: string
  created_at: string
  updated_at: string
  cancelled_at: string | null
}

export async function fetchAppointments(): Promise<Appointment[]> {
  const { data } = await portalApi.get<Appointment[]>('/portal/appointments')
  return data
}

export async function createAppointment(start_at: string, note: string): Promise<Appointment> {
  const { data } = await portalApi.post<Appointment>('/portal/appointments', { start_at, note })
  return data
}

export async function rescheduleAppointment(id: number, start_at: string): Promise<Appointment> {
  const { data } = await portalApi.patch<Appointment>(`/portal/appointments/${id}`, { start_at })
  return data
}

export async function cancelAppointment(id: number): Promise<void> {
  await portalApi.delete(`/portal/appointments/${id}`)
}

export interface PaymentMethod {
  id: string
  brand: string
  last4: string
  exp_month: number
  exp_year: number
  is_default: boolean
}

export async function fetchPaymentMethods(): Promise<PaymentMethod[]> {
  const { data } = await portalApi.get<PaymentMethod[]>('/portal/payment-methods')
  return data
}

export async function createSetupIntent(): Promise<string> {
  const { data } = await portalApi.post<{ client_secret: string }>('/portal/payment-methods/setup-intent')
  return data.client_secret
}

export async function setDefaultPaymentMethod(id: string): Promise<void> {
  await portalApi.post(`/portal/payment-methods/${id}/default`)
}

export async function deletePaymentMethod(id: string): Promise<void> {
  await portalApi.delete(`/portal/payment-methods/${id}`)
}
