<template>
  <Teleport to="body">
    <Transition name="mermaid-modal-fade">
      <div
        v-if="isOpen"
        class="mermaid-modal-overlay"
        @click.self="close"
        @keydown.esc="close"
        tabindex="-1"
        ref="overlayRef"
      >
        <!-- Modal Header Toolbar -->
        <header class="mermaid-modal-header">
          <div class="header-left">
            <div class="header-icon">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <rect width="6" height="6" x="3" y="3" rx="1"/><rect width="6" height="6" x="15" y="3" rx="1"/><rect width="6" height="6" x="9" y="15" rx="1"/>
                <path d="M6 9v3a3 3 0 0 0 3 3h3m3-6v3a3 3 0 0 1-3 3"/>
              </svg>
            </div>
            <span class="header-title">Diagram Inspector</span>
            <span class="header-badge">Interactive</span>
          </div>

          <div class="header-actions">
            <div class="zoom-controls">
              <button class="vp-tool-btn" @click="zoomOut" title="Zoom Out (-)">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
                  <line x1="5" y1="12" x2="19" y2="12"/>
                </svg>
              </button>
              <button class="zoom-display" @click="resetTransform" title="Click to reset to 100%">
                {{ Math.round(scale * 100) }}%
              </button>
              <button class="vp-tool-btn" @click="zoomIn" title="Zoom In (+)">
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round">
                  <line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/>
                </svg>
              </button>
            </div>

            <button class="vp-tool-btn reset-btn" @click="resetTransform" title="Reset View (0)">
              <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <path d="M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8"/><path d="M3 3v5h5"/>
              </svg>
              <span>Reset</span>
            </button>

            <button class="vp-tool-btn close-btn" @click="close" title="Close (Esc)">
              <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
                <line x1="18" y1="6" x2="6" y2="18"/><line x1="6" y1="6" x2="18" y2="18"/>
              </svg>
            </button>
          </div>
        </header>

        <!-- Canvas Container -->
        <main
          class="mermaid-modal-canvas"
          @wheel.prevent="onWheel"
          @mousedown="onMouseDown"
          @mousemove="onMouseMove"
          @mouseup="onMouseUp"
          @mouseleave="onMouseUp"
          @dblclick="resetTransform"
          :class="{ dragging: isDragging }"
        >
          <div
            class="mermaid-svg-wrapper"
            :style="{
              transform: `translate(${panX}px, ${panY}px) scale(${scale})`,
              transformOrigin: 'center center'
            }"
            v-html="currentSvg"
          ></div>
        </main>

        <!-- Bottom Status Bar -->
        <footer class="mermaid-modal-footer">
          <div class="footer-tip">
            <span>Scroll to zoom</span>
            <span class="sep">•</span>
            <span>Drag to pan</span>
            <span class="sep">•</span>
            <span>Double click or press <kbd>0</kbd> to reset</span>
            <span class="sep">•</span>
            <span>Press <kbd>Esc</kbd> to exit</span>
          </div>
        </footer>
      </div>
    </Transition>
  </Teleport>
</template>

<script setup lang="ts">
import { ref, onMounted, onUnmounted, nextTick } from 'vue'

const isOpen = ref(false)
const currentSvg = ref('')
const scale = ref(1)
const panX = ref(0)
const panY = ref(0)
const isDragging = ref(false)
const startX = ref(0)
const startY = ref(0)
const overlayRef = ref<HTMLElement | null>(null)

let observer: MutationObserver | null = null

function open(svgHtml: string) {
  currentSvg.value = svgHtml
  scale.value = 1
  panX.value = 0
  panY.value = 0
  isOpen.value = true
  if (typeof document !== 'undefined') {
    document.body.style.overflow = 'hidden'
  }
  nextTick(() => {
    overlayRef.value?.focus()
  })
}

function close() {
  isOpen.value = false
  currentSvg.value = ''
  if (typeof document !== 'undefined') {
    document.body.style.overflow = ''
  }
}

function zoomIn() {
  scale.value = Math.min(Math.round((scale.value + 0.2) * 100) / 100, 5)
}

function zoomOut() {
  scale.value = Math.max(Math.round((scale.value - 0.2) * 100) / 100, 0.3)
}

function resetTransform() {
  scale.value = 1
  panX.value = 0
  panY.value = 0
}

function onWheel(e: WheelEvent) {
  const delta = e.deltaY < 0 ? 1.15 : 0.85
  const newScale = Math.round(scale.value * delta * 100) / 100
  if (newScale >= 0.25 && newScale <= 5) {
    scale.value = newScale
  }
}

function onMouseDown(e: MouseEvent) {
  if (e.button !== 0) return
  isDragging.value = true
  startX.value = e.clientX - panX.value
  startY.value = e.clientY - panY.value
}

function onMouseMove(e: MouseEvent) {
  if (!isDragging.value) return
  panX.value = e.clientX - startX.value
  panY.value = e.clientY - startY.value
}

function onMouseUp() {
  isDragging.value = false
}

function onKeyDown(e: KeyboardEvent) {
  if (!isOpen.value) return
  if (e.key === 'Escape') close()
  else if (e.key === '+' || e.key === '=') zoomIn()
  else if (e.key === '-') zoomOut()
  else if (e.key === '0') resetTransform()
}

function attachInspectButtons() {
  if (typeof document === 'undefined') return

  const mermaidBlocks = document.querySelectorAll('.mermaid')
  mermaidBlocks.forEach((block) => {
    // If already enhanced with our flat toolbar, skip
    if (block.querySelector('.mermaid-flat-toolbar')) return

    // Find the actual diagram SVG (ignore any button icons)
    const svg = block.querySelector('.mermaid-flat-canvas svg, svg[id^="mermaid-"]')
      || Array.from(block.querySelectorAll('svg')).find((s) => !s.closest('button'))
    if (!svg) return

    // Create the top flat action bar
    const toolbar = document.createElement('div')
    toolbar.className = 'mermaid-flat-toolbar'

    const btn = document.createElement('button')
    btn.className = 'mermaid-flat-action'
    btn.setAttribute('type', 'button')
    btn.setAttribute('title', 'Open diagram in fullscreen inspector (Esc to exit)')
    btn.innerHTML = `
      <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">
        <path d="M15 3h6v6M9 21H3v-6M21 3l-7 7M3 21l7-7"/>
      </svg>
      <span>Fullscreen</span>
    `

    // Wrap diagram SVG in scrollable canvas if not already wrapped
    let canvas = block.querySelector('.mermaid-flat-canvas')
    if (!canvas) {
      canvas = document.createElement('div')
      canvas.className = 'mermaid-flat-canvas'
      svg.parentNode?.insertBefore(canvas, svg)
      canvas.appendChild(svg)
    }

    // Ensure the button explicitly grabs the diagram SVG inside canvas, never its own icon!
    btn.addEventListener('click', (e) => {
      e.stopPropagation()
      const targetSvg = canvas.querySelector('svg')
        || block.querySelector('svg[id^="mermaid-"]')
        || Array.from(block.querySelectorAll('svg')).find((s) => !s.closest('button'))

      if (targetSvg) {
        open(targetSvg.outerHTML)
      }
    })

    toolbar.appendChild(btn)
    block.insertBefore(toolbar, canvas)
  })
}

onMounted(() => {
  window.addEventListener('keydown', onKeyDown)

  nextTick(() => {
    attachInspectButtons()
  })

  // Observe DOM for dynamic renders or route transitions
  observer = new MutationObserver(() => {
    attachInspectButtons()
  })
  observer.observe(document.body, { childList: true, subtree: true })
})

onUnmounted(() => {
  if (typeof window !== 'undefined') {
    window.removeEventListener('keydown', onKeyDown)
  }
  if (observer) {
    observer.disconnect()
  }
})
</script>

<style>
/* Enforce Montserrat font strictly on all diagram and viewer components */
.mermaid,
.mermaid *,
.mermaid svg,
.mermaid svg *,
.mermaid svg text,
.mermaid svg tspan,
.mermaid-modal-overlay,
.mermaid-modal-overlay * {
  font-family: var(--vp-font-family-base) !important;
}

/* Flat, borderless, full-width diagram container */
.mermaid {
  position: relative !important;
  display: flex !important;
  flex-direction: column !important;
  margin: 28px 0 !important;
  padding: 0 !important;
  border: none !important;
  border-radius: 0 !important;
  box-shadow: none !important;
  background: transparent !important;
  width: 100% !important;
  max-width: 100% !important;
}

/* Flat action toolbar above diagram - zero overlap */
.mermaid-flat-toolbar {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  width: 100%;
  margin-bottom: 6px;
  background: transparent;
  border: none;
}

.mermaid-flat-action {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 4px 10px;
  font-size: 12px;
  font-weight: 600;
  line-height: 18px;
  font-family: var(--vp-font-family-base) !important;
  color: var(--vp-c-text-2);
  background: transparent;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  transition: all 0.2s ease;
  user-select: none;
}

.mermaid-flat-action:hover {
  color: var(--vp-c-brand-1);
  background-color: var(--vp-c-default-soft, var(--vp-c-bg-alt));
}

.mermaid-flat-action svg {
  flex-shrink: 0;
}

/* Flat Diagram SVG Canvas */
.mermaid-flat-canvas {
  display: flex;
  justify-content: center;
  align-items: center;
  padding: 10px 0;
  overflow-x: auto;
  width: 100%;
  border: none;
  background: transparent;
}

.mermaid-flat-canvas svg {
  max-width: 100%;
  height: auto;
}

/* Modal Overlay */
.mermaid-modal-overlay {
  position: fixed;
  inset: 0;
  z-index: 100;
  background: var(--vp-backdrop-bg, rgba(0, 0, 0, 0.7));
  backdrop-filter: blur(14px);
  -webkit-backdrop-filter: blur(14px);
  display: flex;
  flex-direction: column;
  outline: none;
  font-family: var(--vp-font-family-base) !important;
}

/* Flat Modal Header */
.mermaid-modal-header {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 12px 24px;
  background-color: var(--vp-c-bg);
  box-shadow: 0 1px 0 var(--vp-c-divider);
  z-index: 10;
  font-family: var(--vp-font-family-base) !important;
}

.header-left {
  display: flex;
  align-items: center;
  gap: 10px;
}

.header-icon {
  display: flex;
  align-items: center;
  color: var(--vp-c-brand-1);
}

.header-title {
  font-size: 14px;
  font-weight: 700;
  color: var(--vp-c-text-1);
  letter-spacing: -0.01em;
  font-family: var(--vp-font-family-base) !important;
}

.header-badge {
  font-size: 11px;
  font-weight: 600;
  padding: 2px 8px;
  border-radius: 9999px;
  background: var(--vp-c-brand-soft);
  color: var(--vp-c-brand-1);
  font-family: var(--vp-font-family-base) !important;
  user-select: none;
}

.header-actions {
  display: flex;
  align-items: center;
  gap: 8px;
}

.zoom-controls {
  display: inline-flex;
  align-items: center;
  background-color: var(--vp-c-bg-alt);
  border-radius: 6px;
  overflow: hidden;
}

.zoom-controls .vp-tool-btn {
  border-radius: 0;
  background: transparent;
  height: 32px;
  width: 32px;
}

.zoom-controls .vp-tool-btn:hover {
  background-color: var(--vp-c-bg-soft);
  color: var(--vp-c-brand-1);
}

.zoom-display {
  font-size: 12px;
  font-weight: 700;
  font-family: var(--vp-font-family-base) !important;
  color: var(--vp-c-text-2);
  min-width: 48px;
  text-align: center;
  padding: 0 4px;
  background: transparent;
  border: none;
  cursor: pointer;
  user-select: none;
  transition: color 0.15s ease;
}

.zoom-display:hover {
  color: var(--vp-c-brand-1);
}

/* Flat Tool Buttons */
.vp-tool-btn {
  display: inline-flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  height: 32px;
  padding: 0 10px;
  border-radius: 6px;
  border: none;
  background-color: var(--vp-c-bg-alt);
  color: var(--vp-c-text-2);
  font-size: 12px;
  font-weight: 600;
  font-family: var(--vp-font-family-base) !important;
  cursor: pointer;
  transition: all 0.15s ease;
  user-select: none;
}

.vp-tool-btn:hover {
  color: var(--vp-c-text-1);
  background-color: var(--vp-c-bg-soft);
}

.vp-tool-btn.close-btn {
  width: 32px;
  padding: 0;
}

.vp-tool-btn.close-btn:hover {
  color: var(--vp-c-text-1);
  background-color: var(--vp-c-bg-soft);
}

/* Modal Canvas */
.mermaid-modal-canvas {
  flex: 1;
  position: relative;
  overflow: hidden;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: grab;
  background-color: var(--vp-c-bg);
}

.mermaid-modal-canvas.dragging {
  cursor: grabbing;
}

.mermaid-svg-wrapper {
  max-width: 90vw;
  max-height: 80vh;
  display: flex;
  align-items: center;
  justify-content: center;
  user-select: none;
  transition: transform 0.05s ease-out;
}

.mermaid-svg-wrapper svg {
  max-width: 88vw !important;
  max-height: 78vh !important;
  width: 100% !important;
  height: auto !important;
  display: block;
}

/* Modal Bottom Status Bar */
.mermaid-modal-footer {
  padding: 10px 24px;
  background-color: var(--vp-c-bg);
  box-shadow: 0 -1px 0 var(--vp-c-divider);
  display: flex;
  align-items: center;
  justify-content: center;
  font-family: var(--vp-font-family-base) !important;
}

.footer-tip {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  justify-content: center;
  gap: 8px;
  font-size: 12px;
  color: var(--vp-c-text-3);
  font-family: var(--vp-font-family-base) !important;
  user-select: none;
}

.footer-tip .sep {
  opacity: 0.5;
}

.footer-tip kbd {
  display: inline-block;
  padding: 2px 6px;
  font-size: 11px;
  font-weight: 600;
  font-family: var(--vp-font-family-base) !important;
  background-color: var(--vp-c-bg-alt);
  border: none;
  border-radius: 4px;
  color: var(--vp-c-text-2);
}

/* Transition Animations */
.mermaid-modal-fade-enter-active,
.mermaid-modal-fade-leave-active {
  transition: opacity 0.2s ease, transform 0.2s ease;
}

.mermaid-modal-fade-enter-from,
.mermaid-modal-fade-leave-to {
  opacity: 0;
}
</style>
