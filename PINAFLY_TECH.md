# Pinafly — technical approach

Status: exploration. Written 2026-06-23. Companion to PINAFLY.md (the strategy brief).

How to build the Pinafly extension on top of the pinnable anchoring engine: what to reuse, what to
build new, the format decisions, and the parts that will hurt if you get them wrong.

The headline: the three-anchor design already in `app/assets/javascripts/pinnable.js` is the right
core and it's already the W3C model. The real work is everything around it — page freezing, the MV3
extension shell, the hosted viewer, and storing the captured pages. Two decisions carry real risk:
the snapshot license (SingleFile is AGPL) and the Chrome Web Store review (reading all-site DOM and
uploading it is a flagged pattern). The snapshot serving itself is deliberately simple: script-free
static files on a content domain, the read-later model (see §5).

---

## 0. Stack — Rails + DigitalOcean, one JS exception

Everything that can be Rails + DO is:

- **API + data + viewer + auth + email + billing**: one Rails app — the pinnable engine grown into
  the product — on DO App Platform (or a Droplet).
- **Database**: DO Managed Postgres. The engine's portable schema (no JSONB, string ids) already runs
  on it unchanged.
- **Snapshot + screenshot storage and static serving**: DO Spaces + its CDN. Content-addressed
  objects, brotli at rest, served from a content domain.
- **Email** (invites, @mention notifications, magic links): a transactional email API service
  (Postmark or Resend), called via its API. Action Mailer stays the Rails-side interface — just point
  its delivery method at the provider's API gem instead of SMTP, so mailer code stays idiomatic.

The only thing that can't be Rails is the **browser extension** itself (MV3 means TS/JS) and the small
shared **anchor-core** it uses — which the in-snapshot marker script reuses too. That's the entire
non-Rails footprint.

---

## 1. Shape of the system

Three runtimes, one shared core.

```
packages/anchor-core         framework-neutral TS. No chrome.*, no Stimulus, no Rails.
  buildAnchors(el, click, root)   -> {cssPath, xPath, textQuote{exact,prefix,suffix}, point}
  resolveAnchors(anchors, root)   -> Element | null   (css -> xpath -> fuzzy text, first hit)
  projectMarker(el, point, origin)-> {top, left}
  serializeSnapshot(root, fetchAsset) -> SnapshotDoc

extension (WXT, MV3)         live arbitrary pages. Imports anchor-core (bundled into the IIFE).
rails guest viewer           frozen snapshot. Imports the SAME anchor-core.
```

The reason to extract a shared package rather than reimplement: a pin placed in the extension must
land on the exact same element when a guest opens the frozen snapshot in the viewer. That equivalence
only holds if both call the same compiled `resolveAnchors`/`projectMarker`. A flat screenshot can
never re-anchor a marker to "the third pricing card" — only re-resolvable selectors against a real
DOM can. That single requirement is why DOM serialization (not just pixels) is the primary snapshot
artifact, and why the anchoring code has to be shared.

Monorepo: pnpm workspace with the Rails app, the WXT extension, and `anchor-core`. The extension's
bundler inlines anchor-core (MV3 content scripts can't be ES modules — see §3). The Rails app imports
the same package through esbuild/Vite. One source of truth, no drift.

---

## 2. The snapshot — the crux feature

Goal: when the user clicks and comments, freeze the page so it re-renders later exactly as seen, from
our own backend, for a viewer with no extension.

**Capture both artifacts, every time, in the same user gesture:**

1. **Self-contained HTML** (primary). Inline every subresource as a `data:` URI, strip all scripts.
   This is the only format that's origin-independent by construction: it makes no network requests,
   renders in any browser, drops straight into a sandboxed iframe, and stays re-anchorable.
2. **Full-page screenshot** (always, alongside). Pixel ground-truth. It's the only artifact immune to
   re-render breakage and the only thing that captures WebGL/canvas/paywall/A-B state the HTML can't
   reconstruct. You cannot rebuild one from the other, so keep both.

Rejected: MHTML (Chrome-only, main-frame-only, downloads instead of rendering when served over HTTP).
Fallback for pages the HTML can't reproduce (heavy SPA/canvas): self-hosted WACZ + ReplayWeb.page as
an escape hatch, not the default.

**The hard cases and how they land** (these are where fidelity is won or lost):

| Case | Handling | Verdict |
|---|---|---|
| Lazy-loaded images | Spoof "fully scrolled": flip `loading=lazy` to eager, fire IntersectionObserver callbacks with `isIntersecting:true`, patch `src/srcset` setters. (Don't literally scroll.) | Solved, but it's the fiddly part |
| Form/input/checkbox/select state | The live value lives in the `.value`/`.checked` **property**, not the serialized attribute. Walk all controls and write live state into attributes before serializing. | Solvable, must not skip |
| Web fonts | Inline `@font-face` binaries as data URIs at capture; no CORS at re-render | Solved |
| 2D canvas | `canvas.toDataURL()` at capture, store as image | Solved |
| WebGL canvas | needs `preserveDrawingBuffer:true` at context creation, which you can't retrofit on a page you don't own — usually reads black | Lost → screenshot covers it |
| Closed shadow DOM | only reachable via `chrome.dom.openOrClosedShadowRoot` (extension-only API) | Captured in extension, lost elsewhere |
| Cross-origin iframes | inject content script into the frame (needs host permission), else accept loss | Best-effort |
| Scroll position | not in serialized HTML — record `scrollX/Y` as metadata, restore on render | Capture as metadata |
| SVG `<use>` external refs | fetch the external sprite at capture, inline, rewrite to local `#fragment` | Solved at capture |
| Page CSP blocking inline style | irrelevant once you re-serve your own copy with your own headers | Solved at serve time |

**Full-page screenshot mechanics:** default to `chrome.tabs.captureVisibleTab` + scroll-and-stitch.
Watch the real traps: the hard rate limit is 2 captures/sec (so ~500ms per stop, which also lets lazy
content paint), multiply by `devicePixelRatio`, neutralize `position:fixed`/`sticky` before stitching
or the header double-exposes, and the canvas cap is 16,384px/side and ~268MP area — tall feeds must
tile across multiple canvases. Avoid the CDP `Page.captureScreenshot` one-shot: it needs
`chrome.debugger`, which shows a persistent non-dismissible "started debugging this browser" banner.
Fine for an enterprise force-installed build, unacceptable for consumer.

**Storage economics:** ~2 MB compressed per snapshot is a fair planning average (brotli at rest,
served `Content-Encoding: br`). Content-address each asset by hash and store once — on a repeat-heavy
corpus (same sites/app captured often) that recovers 40-60% of bytes. At 1M snapshots this is single-
digit dollars/month of storage on DO Spaces; egress is the only real cost lever, and Spaces' included
CDN + 1 TiB base covers a lot. Storage is not the constraint; getting the isolation right is.

---

## 3. The MV3 extension

**Three contexts, fixed responsibilities:**

- **Content script (the brain).** Capture-phase click interception + anchoring (ports almost verbatim
  from the Stimulus controller), DOM serialization, and the Shadow-DOM UI (toolbar, composer,
  markers). Mount the whole UI in a shadow root with `adoptedStyleSheets` + `contain` so host-page CSS
  can't reach in and ours can't leak out; keep the overlay `pointer-events:none` except the actual
  chrome so it never steals the click from the element being annotated.
- **Service worker (stateless mouth/hands).** All backend fetch (content-script fetch is subject to
  the visited page's CORS; SW fetch runs from the extension origin) and `captureVisibleTab` (only
  callable here). It's killed after ~30s idle, so hold nothing in memory — auth token, pin cache, and
  in-flight upload state go in `chrome.storage`. Treat it as a pure handler that can die between any
  two messages; make snapshot uploads idempotent and resumable.
- **Offscreen document.** Canvas stitching only (the SW has no DOM).

**Capture-phase interception holds up across real sites.** A capture-phase listener on `document`
(or `window`, one level earlier) fires before the target's own handlers. React 17+ attaches its root
listener to the React root, not `document`, so `document`-capture + `stopPropagation()` still
intercepts before React's synthetic handler. Intercept `pointerdown`/`mousedown`/`click` (some
controls act on press, not click) but only while comment mode is on, so the page behaves normally
otherwise.

**Auth changes from the gem.** You no longer ride a Rails session cookie inside a foreign page. Issue
the extension a bearer token (device/OAuth flow), store it in `chrome.storage`, send it as a header
from the SW. The CSRF-meta approach in the current widget doesn't apply.

**Toolchain: WXT.** It's the most actively maintained framework, is framework-agnostic (Stimulus is a
non-issue), and `createShadowRootUi()` / `injectScript()` give you the shadow mount and MAIN-world
injection for free. Plasmo is React-first and in maintenance mode; CRXJS is lower-level (you'd
hand-roll manifest, mount, packaging). MV3 content scripts can't be ES modules, so anchor-core must be
authored as plain ESM that the bundler inlines into one IIFE.

**Cross-browser:** Chrome + Edge (same package, free) for v1. Firefox is a real port (event page, no
`chrome.offscreen`) — defer to v2; WXT keeps it cheap to add later.

---

## 4. Anchoring — keep it, then make one upgrade

The current three-anchor scheme (CSS path → XPath → text-quote, re-resolve in order, unanchored tray
on total miss) is already the W3C Web Annotation "multiple selectors with fallback" pattern. Keep it.

**The one weakness worth fixing first:** text-quote matching is exact-substring on the first hit, with
no disambiguation. When the same text appears twice, or the page edits slightly, it grabs the wrong
element or misses. The highest-leverage upgrade is Hypothesis-style **fuzzy text-quote with
prefix/suffix context**: store ~32 chars of surrounding text and match approximately (diff-match-patch
/ Bitap), so the quote survives minor edits and disambiguates repeats. Add a `TextPositionSelector`
(global char offset) as a cheap fourth anchor, and prefer a stable attribute (`data-testid`, `id`)
when one exists. Libraries: `dom-anchor-text-quote` / `dom-anchor-text-position` or Apache Annotator.

**Frozen vs live is the insight that de-risks this.** On the frozen snapshot the DOM is immutable, so
anchoring is essentially exact and trivial — and the snapshot is the surface guests actually view.
Treat the snapshot as the primary anchoring target (stable, exact) and live-page re-anchoring as
best-effort. That inverts the usual fragility: most of the time you're resolving against a DOM that
can't drift.

---

## 5. Backend + the viewer — store static files, serve from a content domain

The model is the read-later one, with one correction. Those apps (Pocket, Instapaper, Wallabag) ran
*extraction*: strip everything but the article, re-render in their own template, so there was no
original HTML left to misbehave. Pinafly keeps full fidelity, so the stored file is the real page.
Two cheap rules make "store the file, serve it static" safe, and then it genuinely is static-and-done.

1. **Strip the captured page's scripts at capture time.** You do this anyway — a frozen snapshot must
   not run the page's JS (it would phone home, repaint, break the freeze). Once the stored file has no
   page `<script>`, serving it static is safe by construction. Then add back one small **first-party**
   marker script (ours) that re-anchors pins and draws the dots. It's our code, talking to our API.
2. **Serve from a separate domain, not the app's.** Store and serve snapshots under a content domain
   (e.g. `pinaflyusercontent.com`) that shares no cookies with the app. If the script-stripper ever
   misses something, it runs in a cookieless origin with nothing to steal, instead of as a logged-in
   user on the app domain. One-time infra, no per-request work.

That is the whole security story. No sandboxed iframe, no deny-all CSP, no nonce machinery — that
stack was only needed for serving *unstripped* HTML from the app's own origin, which we're not doing.

**Serving, all on DO Spaces:**

- Store each snapshot as a self-contained static HTML file (frozen page, page scripts stripped, our
  marker script added) plus the full-page screenshot. Content-addressed, brotli, in DO Spaces.
- Serve through the **Spaces CDN on a custom content domain**. Files get unguessable random keys (the
  Loom/Dropbox model), so the URL itself is the access control for shared links. For login-required
  snapshots, mint short-TTL **presigned URLs** from Rails instead.
- Keep copies of other people's pages out of search by injecting
  `<meta name="robots" content="noindex,noarchive">` into the stored HTML (we control the file) and
  putting a disallow-all `robots.txt` at the content domain root. Both are just static objects in
  Spaces — no header plumbing needed.

**Markers:** the marker script baked into the snapshot fetches that snapshot's pins from the Rails API
(CORS-allowed for the content domain), re-anchors them with the shared anchor-core, and draws dots
in-document (native coordinates, scroll/resize just work). Clicking a dot opens the thread — either in
a Rails viewer page that embeds the snapshot, or by linking back to the app. The thread UI, replies,
and auth all live in Rails; the static file only renders the page and its dots.

**Privacy/legal, unchanged from the strategy doc** (product/legal choices, not architecture weight):
private by default (unguessable or presigned URLs, never public-listed), `noindex`/`noarchive`,
capture only what the user's own session already rendered (no server-side fetching past paywalls —
that's where archive-style liability concentrates), refuse banking/health/gov domains and skip
password/autofill fields at capture, offer region redaction before sharing, register a DMCA agent and
build a takedown endpoint.

---

## 6. Schema evolution — the gem's design pays off here

The existing pinnable schema absorbs most of this with little new code, because it's already
polymorphic, portable-typed, and opaque-id'd.

- **Snapshots are per page-version, not per pin.** Many pins sit on one capture of a page. Model a
  `PageVersion` keyed by `(tenant, url_hash, content_hash)`; pins belong to a version; the `Snapshot`
  (storage_key, content_hash, byte_size, screenshot_key, captured_at) belongs to the version. Add a
  **nullable** `page_version` ref to `pinnable_pins` — nullable keeps the current snapshot-less engine
  working unchanged. Re-capturing changed content makes a new version (history); pins stay on the
  version they were made on, so a marker never drifts onto a page it wasn't placed on.
- **Guests need almost no new engine code.** `Comment.author` is already polymorphic and optional, and
  the engine already stores `author_label` so the inbox never needs the host User. A guest replier is
  just `author_type="Pinnable::Guest"` with a label — and `MarkerSerializer` already emits only the
  label, so it works unchanged. Add a light `Pinnable::Guest` (email-on-first-reply, magic-link
  verify).
- **Teams/memberships/subscriptions** live in the product app, not the engine (keeps the engine
  reusable). Pins/snapshots set `tenant_type="Team"`; existing `%i[tenant_type tenant_id]` index
  already scopes them. A **seat** is an accepted membership (a User); guests reply free. That's the
  clean billing line.
- **@mentions** parse in the existing `AddComment` service → `Mention` + `Notification` rows → Action
  a transactional email API (Postmark/Resend). Rails 8 built-ins cover the auth side (sessions for
  teammates, `generates_token_for` + magic links for guests); the mailers deliver through the provider
  API. For snapshots, write directly to DO Spaces with the AWS SDK / `s3cmd` (the same setup mbuzz
  already uses) rather than ActiveStorage — you want full control of the object key (random/unguessable
  on the content domain) and presigned URLs, which is more direct than ActiveStorage's blob pipeline.
  ActiveStorage stays fine for incidental app uploads (avatars).

Keep portable types, `has_secure_token` public_ids, and opt-in `encrypts` (turn it on for `body`,
`anchor`, guest `email`) throughout.

---

## 7. The two decisions that carry real risk

**License: SingleFile is AGPL-3.0** (including `single-file-core`). Bundling it into a closed-source
extension + SaaS that serves snapshots is exactly what the AGPL network clause covers. Options: buy
the commercial license the author explicitly offers, or build your own inliner. Given you have to add
form-state/canvas/scroll handling on top anyway, building your own is a credible path — the techniques
are documented (§2). Don't ship AGPL code in the closed product. (Get counsel to confirm.)

**Web Store review: HIGH risk if done the obvious way.** An extension that reads all-site DOM and
uploads it hits two of the most-scrutinized triggers at once (broad host permissions + collecting
website content), and remote code is banned in MV3 so the anchoring engine must be bundled. Mitigate
by shipping v1 on **`activeTab` + `scripting`**, injecting on toolbar click, instead of `<all_urls>`.
That matches the product ("annotate *this* page on demand"), carries no install-time warning, and
dodges the in-depth-review queue — days instead of weeks. A privacy policy + Limited Use certification
are mandatory regardless because you collect website content; describe the capture feature prominently
in the listing and the UI. Reserve `<all_urls>` for a later always-on-markers feature and expect to
justify it hard.

---

## 8. v1 build order

1. `anchor-core` package: extract + port the existing builders/resolver, add fuzzy text-quote.
2. WXT extension shell: comment mode, capture-phase anchoring, shadow-DOM UI, bearer-token auth.
3. Own HTML inliner + scroll-stitch screenshot, both in the content script; SW does upload.
4. Rails: `PageVersion` + `Snapshot` models, DO Spaces (content-addressed, brotli, presigned).
5. Static snapshots in Spaces on the **content domain** (unguessable keys, injected `noindex`), with
   the baked-in first-party marker script. Rails viewer page for no-install read + reply.
6. Teams/seats/Stripe, @mention email. One free tier, one paid seat tier. Consumer plan later.

Cut for v1: public/SEO snapshots, Firefox, WACZ fallback, CDP screenshot, always-on markers.

The first thing to prototype before committing: the **own HTML inliner** on 20 real target pages
(a vibe-coded UI, a SaaS dashboard, a marketing page, an app mid-bug). If your inliner can't reproduce
those faithfully, the whole wedge is shaky and you want to know that in week one, not month three.
