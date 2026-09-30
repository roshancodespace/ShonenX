/// <reference path="./env.d.ts" />
import DefaultTheme from 'vitepress/theme'
import { h } from 'vue'
import MermaidZoom from './MermaidZoom.vue'
import './custom.css'

export default {
  extends: DefaultTheme,
  Layout() {
    return h(DefaultTheme.Layout, null, {
      'layout-bottom': () => h(MermaidZoom)
    })
  }
}
