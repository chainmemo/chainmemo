import { createRouter, createWebHistory } from 'vue-router'
import Home from '../views/Home.vue'
import Read from '../views/Read.vue'
import Write from '../views/Write.vue'
import PassGen from '../views/PassGen.vue'

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/read',
    name: 'Read',
    component: Read
  },
  {
    path: '/write',
    name: 'Write',
    component: Write
  },
  {
    path: '/passgen',
    name: 'PassGen',
    component: PassGen
  }
]

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes
})

export default router
