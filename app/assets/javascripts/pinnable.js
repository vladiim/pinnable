import { Application, Controller } from "@hotwired/stimulus"

// ----------------------------------------------------------------------------
// Anchoring — no dependencies. Each pin stores three independent anchors and we
// re-resolve them in order (css -> xpath -> text quote); the redundancy is why a
// "dumb" structural selector is enough. See lib/specs/069 in the host app.
// ----------------------------------------------------------------------------

const MAX_QUOTE = 80

function cssPath(el) {
  if (el.id) return `#${cssEscape(el.id)}`
  const parts = []
  let node = el
  while (node && node.nodeType === 1 && node !== document.body) {
    if (node.id) { parts.unshift(`#${cssEscape(node.id)}`); break }
    const tag = node.tagName.toLowerCase()
    const i = nthOfType(node)
    parts.unshift(i ? `${tag}:nth-of-type(${i})` : tag)
    node = node.parentElement
  }
  return parts.join(" > ")
}

function nthOfType(node) {
  const siblings = Array.from(node.parentElement?.children || []).filter(n => n.tagName === node.tagName)
  return siblings.length > 1 ? siblings.indexOf(node) + 1 : 0
}

function xpathOf(el) {
  if (el.id) return `//*[@id=${xpathLiteral(el.id)}]`
  const parts = []
  let node = el
  while (node && node.nodeType === 1 && node !== document.body) {
    if (node.id) { parts.unshift(`*[@id=${xpathLiteral(node.id)}]`); break }
    parts.unshift(`${node.tagName.toLowerCase()}[${sameTagIndex(node)}]`)
    node = node.parentElement
  }
  return "//" + parts.join("/")
}

function sameTagIndex(node) {
  let i = 1, sib = node
  while ((sib = sib.previousElementSibling)) if (sib.tagName === node.tagName) i++
  return i
}

function textQuote(el) {
  return { exact: (el.textContent || "").trim().replace(/\s+/g, " ").slice(0, MAX_QUOTE) }
}

function captureAnchor(el, event) {
  const r = el.getBoundingClientRect()
  return {
    css: cssPath(el),
    xpath: xpathOf(el),
    ...textQuote(el),
    tag: el.tagName.toLowerCase(),
    x_pct: r.width ? round((event.clientX - r.left) / r.width) : 0,
    y_pct: r.height ? round((event.clientY - r.top) / r.height) : 0
  }
}

function resolveAnchor(anchor) {
  let el = null
  try { if (anchor.css) el = document.querySelector(anchor.css) } catch (_) {}
  if (!el && anchor.xpath) el = byXPath(anchor.xpath)
  if (!el && anchor.exact) el = byText(anchor.exact)
  return el
}

function byXPath(xpath) {
  try {
    return document.evaluate(xpath, document, null, XPathResult.FIRST_ORDERED_NODE_TYPE, null).singleNodeValue
  } catch (_) { return null }
}

function byText(exact) {
  const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_ELEMENT)
  let node
  while ((node = walker.nextNode())) {
    if (node.closest(".pinnable")) continue
    const text = (node.textContent || "").trim().replace(/\s+/g, " ")
    if (node.children.length === 0 && text.includes(exact)) return node
  }
  return null
}

function cssEscape(s) { return window.CSS && CSS.escape ? CSS.escape(s) : s.replace(/([^\w-])/g, "\\$1") }
function xpathLiteral(s) { return s.includes("'") ? `concat('${s.split("'").join(`',"'",'`)}')` : `'${s}'` }
function round(n) { return Math.round(n * 1000) / 1000 }

// ----------------------------------------------------------------------------
// Controller — toggle comment mode, capture clicks, render + work pins.
// ----------------------------------------------------------------------------

class PinnableController extends Controller {
  static values = { pinsUrl: String, markersUrl: String, currentUrl: String, focus: String, csrf: String }
  static targets = ["toggle"]

  connect() {
    this.active = false
    this.onClick = this.onClick.bind(this)
    this.onMove = this.onMove.bind(this)
    this.loadMarkers()
  }

  disconnect() { this.deactivate() }

  toggle() { this.active ? this.deactivate() : this.activate() }

  activate() {
    this.active = true
    this.toggleTarget.textContent = "💬 Comments: On"
    this.toggleTarget.classList.add("pinnable-toggle--on")
    document.addEventListener("click", this.onClick, true)
    document.addEventListener("mousemove", this.onMove, true)
  }

  deactivate() {
    this.active = false
    if (this.hasToggleTarget) {
      this.toggleTarget.textContent = "💬 Comments: Off"
      this.toggleTarget.classList.remove("pinnable-toggle--on")
    }
    document.removeEventListener("click", this.onClick, true)
    document.removeEventListener("mousemove", this.onMove, true)
    this.clearHighlight()
  }

  onMove(event) {
    const el = this.elementUnder(event)
    if (el === this.highlighted) return
    this.clearHighlight()
    if (el) { this.highlighted = el; this.prevOutline = el.style.outline; el.style.outline = "2px solid #6366f1" }
  }

  clearHighlight() {
    if (!this.highlighted) return
    this.highlighted.style.outline = this.prevOutline || ""
    this.highlighted = null
  }

  onClick(event) {
    const el = this.elementUnder(event)
    if (!el) return
    event.preventDefault()
    event.stopPropagation()
    this.clearHighlight()
    this.openComposer(el, event)
  }

  elementUnder(event) {
    const el = event.target
    if (!el || el.closest(".pinnable, .pinnable-composer, .pinnable-pop, .pinnable-tray, .pinnable-marker")) return null
    return el
  }

  openComposer(el, event) {
    this.closeComposer()
    const anchor = captureAnchor(el, event)
    const box = document.createElement("div")
    box.className = "pinnable-composer"
    box.style.left = `${event.pageX}px`
    box.style.top = `${event.pageY}px`
    box.innerHTML = `<textarea class="pinnable-composer__text" placeholder="Leave feedback…"></textarea>
      <div class="pinnable-composer__actions">
        <button type="button" class="pinnable-composer__cancel">Cancel</button>
        <button type="button" class="pinnable-composer__save">Save</button>
      </div>`
    document.body.appendChild(box)
    this.composer = box
    box.querySelector(".pinnable-composer__text").focus()
    box.querySelector(".pinnable-composer__cancel").addEventListener("click", () => this.closeComposer())
    box.querySelector(".pinnable-composer__save").addEventListener("click", () => this.save(anchor, box))
  }

  closeComposer() { if (this.composer) { this.composer.remove(); this.composer = null } }

  async save(anchor, box) {
    const body = box.querySelector(".pinnable-composer__text").value.trim()
    if (!body) return
    const res = await this.post(this.pinsUrlValue, { pin: { url: this.currentUrlValue, body, anchor } })
    if (!res.ok) return
    const { public_id } = await res.json()
    this.closeComposer()
    this.addMarker({ public_id, body, anchor })
  }

  async loadMarkers() {
    const res = await fetch(`${this.markersUrlValue}?url=${encodeURIComponent(this.currentUrlValue)}`, {
      headers: { "Accept": "application/json" }
    })
    if (!res.ok) return
    const pins = await res.json()
    pins.forEach(pin => this.addMarker(pin))
    if (this.focusValue) this.focusPin(this.focusValue)
  }

  addMarker(pin) {
    const el = resolveAnchor(pin.anchor)
    if (!el) return this.addUnanchored(pin)
    const r = el.getBoundingClientRect()
    const dot = document.createElement("button")
    dot.type = "button"
    dot.className = "pinnable-marker"
    dot.dataset.pinId = pin.public_id
    dot.style.left = `${window.scrollX + r.left + (pin.anchor.x_pct || 0) * r.width}px`
    dot.style.top = `${window.scrollY + r.top + (pin.anchor.y_pct || 0) * r.height}px`
    dot.textContent = "📌"
    dot.title = pin.body
    dot.addEventListener("click", (e) => { e.preventDefault(); this.openPopover(dot, pin) })
    document.body.appendChild(dot)
  }

  addUnanchored(pin) {
    let tray = document.querySelector(".pinnable-tray")
    if (!tray) {
      tray = document.createElement("div")
      tray.className = "pinnable-tray"
      tray.innerHTML = "<strong>Unanchored here</strong>"
      document.body.appendChild(tray)
    }
    const item = document.createElement("button")
    item.type = "button"
    item.className = "pinnable-tray__item"
    item.dataset.pinId = pin.public_id
    item.textContent = pin.body
    tray.appendChild(item)
  }

  openPopover(dot, pin) {
    this.closePopover()
    pin.comments = pin.comments || []
    const pop = document.createElement("div")
    pop.className = "pinnable-pop"
    pop.style.left = dot.style.left
    pop.style.top = `${parseFloat(dot.style.top) + 22}px`
    pop.innerHTML = `
      <p class="pinnable-pop__body"></p>
      <div class="pinnable-pop__thread"></div>
      <form class="pinnable-pop__reply">
        <input type="text" class="pinnable-pop__input" placeholder="Reply…">
      </form>
      <button type="button" class="pinnable-pop__resolve">Resolve</button>`
    pop.querySelector(".pinnable-pop__body").textContent = pin.body
    document.body.appendChild(pop)
    this.pop = pop
    this.renderThread(pop, pin)
    pop.querySelector(".pinnable-pop__resolve").addEventListener("click", () => this.resolve(pin, dot))
    pop.querySelector(".pinnable-pop__reply").addEventListener("submit", (e) => { e.preventDefault(); this.reply(pin, pop) })
  }

  renderThread(pop, pin) {
    const thread = pop.querySelector(".pinnable-pop__thread")
    thread.innerHTML = ""
    pin.comments.forEach((c) => {
      const row = document.createElement("div")
      row.className = "pinnable-pop__comment"
      const who = document.createElement("span")
      who.className = "pinnable-pop__author"
      who.textContent = c.author_label
      const text = document.createElement("span")
      text.textContent = c.body
      row.append(who, text)
      thread.appendChild(row)
    })
  }

  async reply(pin, pop) {
    const input = pop.querySelector(".pinnable-pop__input")
    const body = input.value.trim()
    if (!body) return
    const res = await this.post(`${this.pinsUrlValue}/${pin.public_id}/comments`, { comment: { body } })
    if (!res.ok) return
    const comment = await res.json()
    pin.comments.push({ author_label: comment.author_label, body: comment.body })
    this.renderThread(pop, pin)
    input.value = ""
  }

  closePopover() { if (this.pop) { this.pop.remove(); this.pop = null } }

  async resolve(pin, dot) {
    const res = await this.post(`${this.pinsUrlValue}/${pin.public_id}`, { pin: { status: "resolved" } }, "PATCH")
    if (!res.ok) return
    this.closePopover()
    dot.remove()
  }

  focusPin(publicId) {
    const dot = document.querySelector(`.pinnable-marker[data-pin-id="${publicId}"]`)
    if (!dot) return
    dot.scrollIntoView({ block: "center", behavior: "smooth" })
    dot.classList.add("pinnable-marker--flash")
  }

  post(url, payload, method = "POST") {
    return fetch(url, {
      method,
      headers: { "Content-Type": "application/json", "Accept": "application/json", "X-CSRF-Token": this.csrfValue },
      body: JSON.stringify(payload)
    })
  }
}

const application = Application.start()
application.register("pinnable", PinnableController)
