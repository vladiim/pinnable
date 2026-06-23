# Pinafly — strategy brief

Status: exploration. Written 2026-06-23. Decision pending.

A browser extension that pins element-anchored comments on any website, freezes the page
(HTML + screenshot) so the annotated version re-renders exactly as it was seen, and lets you
@mention people to collaborate. Freemium: a small consumer plan, real money on business seats.

Name: **Pinafly** (pinafly.com available). Pin + fly. Brand can lean Superfly-70s: the fly that
lands on the page and stays put. Keep that for the wordmark and launch art, not the product copy.

---

## What this is, and what it isn't

The current `pinnable` gem is a Rails engine that drops feedback-commenting *inside your own app*,
gated to your own admins. Buyer: a Rails dev embedding it. That is a different product from Pinafly.

Pinafly is a **browser extension that works on anyone's site**, with page archival and outside-team
collaboration. Different buyer, different moat, different growth.

What carries over is the part that's hard to build: the anchoring engine (CSS selector → XPath →
text-quote, re-resolved in order on each load, with an unanchored tray when all three miss) and the
open→resolved task model. Everything else is new: a Manifest V3 extension, a hosted multi-tenant
backend, auth, billing, and the snapshot store. Treat this as a new product that borrows pinnable's
hardest-won piece, not as "pinnable with a Chrome wrapper." Roughly 80% new surface.

---

## Does it exist? No — the four-pillar combination is unoccupied

The exact combination — element-anchored comments + a frozen re-renderable HTML snapshot + @mention
collaboration + freemium consumer→biz — does not exist as one product. The market splits into camps
that each own two or three pillars and miss the rest.

| Pillar | Who does it well | Who's missing it |
|---|---|---|
| Element-anchored DOM comments | Heurio, Simple Commenter, Commented.io, BugHerd, Userback, Marker.io, ruttl, Pastel | every annotation tool (text-only), every screenshot tool (flat image), every archive tool |
| Frozen re-renderable HTML snapshot | SingleFile, Wayback, Conifer, Diigo (paid), Memex | every element-anchored commenting tool |
| @mention collaboration | BugHerd, Marker.io, Userback, Ziflow, Filestage, Heurio | archive tools (all), most annotation tools |
| Freemium consumer→biz | Userback, Pastel, ruttl, Heurio, Web Highlights | Marker.io / BugHerd (no free tier) |

Closest incumbents and what they don't do:

- **Heurio** — closest overall. Element-anchored pins on live sites, Chrome extension, freemium
  ($0 → $9.90/seat), ~30k users, chasing the AI vibe-coding feedback wave (Lovable, v0, Bolt,
  Replit). Does **not** archive the HTML; comments anchor to the live DOM and drift when the page
  changes.
- **Simple Commenter** — clean "pinned to the exact HTML element, persists across deploys" story,
  and **explicitly positions against snapshots** ("not a screenshot that goes stale"). It has
  actively chosen away from our wedge.
- **BugHerd / Userback** — element pins + @mentions, and Userback has the best DOM serialization in
  the field. But it's framed as transient session-replay, not a durable, ownable, re-renderable page
  archive, and they skip iframe/video/canvas. BugHerd has no free tier.
- **Ziflow** — the only one that explicitly "creates a snapshot of the web page" with @mentions, but
  pins are coordinate-on-image, not DOM-element, and it's $199+/mo enterprise.
- **SingleFile** — owns the exact archiving primitive we'd build on (self-contained HTML, ~500k
  installs, free). No comments, no collaboration, no business model. A feature to absorb, not a
  workflow competitor.

The wedge is real: open a teammate's comment and see the page exactly as they saw it, even after a
deploy. Heurio/BugHerd/Pastel structurally can't do that (live render); SingleFile/Diigo can't pair
it with collaboration. The combination is the product.

The honest caveat: "unoccupied" can mean nobody fused them, or the two camps split on purpose because
buyers don't want them fused. Pastel and Simple Commenter sell *against* snapshots — for a live site,
a stale copy is worse than the live page. So the snapshot only wins where the page is **ephemeral or
changing**: AI-generated UIs, A/B variants, a checkout flow caught mid-bug, anything that'll look
different tomorrow. That's the wedge to aim at, not generic website feedback.

---

## Does it have legs as a $10–20k/mo business? Yes — but as B2B seats, not a consumer extension

The load-bearing finding: the consumer freemium path does not get there.

- Web Highlights: 200k installs → ~$2k MRR.
- GoFullPage: 11M installs → ~$120k/yr (about $0.011 per install per year).
- Freemium extension free→paid conversion runs 0.5–2%. Chrome killed native store billing in 2021,
  so you bill through Stripe/ExtensionPay, adding friction at the upgrade step.

The tools that clear $180k+ ARR here monetize **per-seat business plans**:

| Tool (closest analogs first) | Revenue | Team | Model |
|---|---|---|---|
| ruttl | ~$660k ARR | 6–7 | $18/seat/mo |
| Marker.io | ~$492k ARR, ~1,500 customers | 8 | team tiers $39–$159 |
| BugHerd | ~$2.5M ARR | 17 (funded) | flat tiers $42–$150 |
| Markup Hero | ~$20k MRR / ~$15k profit | 3 | $4 consumer + AppSumo |
| Web Highlights | ~$2k MRR on 200k installs | solo | consumer freemium |

(Revenue figures are third-party estimates — Latka and similar — not founder-audited. Install counts
and the Markup Hero / ruttl founder-stated numbers are the firmest points.)

The math to $15k/mo:

- Consumer-only: ~1,875 payers → ~190k active installs at 1% conversion. That's Web Highlights'
  entire base, which makes ~$2k. Don't model it this way.
- Blended (realistic): ~700 consumer × $8 = $5.6k, plus ~95 teams × ~4 seats × $25 = $9.4k. Needs
  ~40–60k installs feeding the consumer line **and** a separate content/SEO/outbound funnel for the
  teams. Roughly 80–90% of revenue is the business seats.

So $10–15k/mo is reachable and matches a real bootstrapped shape (3–8 people). $20k/mo is the upper
end of independent outcomes in this category. It's a B2B SaaS with the extension as the wedge, not a
consumer flywheel. And it's slow: BugHerd took ~13 years and a funded 17-person team to reach $2.5M.

---

## "Viral built in" — half true. The half you like is the weak one.

Two loops are real:

**1. Guest-comment loop (strong, well-precedented).** A user pins comments, @mentions a client,
shares a link; the recipient comments back. The archived snapshot is perfect for this — they view the
frozen page and reply in a bare browser. Markup.io self-reported ~15k invites in a quarter as a top-3
growth source; Pastel's founder line is that the best growth hack is "a product that only works when
used with other people."

> Make-or-break: the shared comment must be viewable and replyable with **no install and no account**.
> Gate that and the loop dies. This single design decision is the whole virality story.

**2. @mention seat-expansion (strong but bounded).** Compounds inside an org, then saturates at the
company boundary. Good land-and-expand; not net-new logos.

The loop "viral built in" probably means — **public archived+annotated pages as an SEO surface** — is
the weakest and riskiest. Glasp is the only tool that built it: 900k+ Search Console impressions, and
the founders state on record it converted poorly to signups (it attracts readers, not creators) and
they had to de-index pages over privacy. On top of that you'd be hosting public copies of other
people's copyrighted, sometimes paywalled pages — DMCA and privacy exposure. A "make public" toggle
can exist as a convenience. Do not build the business on it.

Honest reframe: this is bounded team/agency virality in the BugHerd/Markup/Pastel lineage, not
Loom-class consumer virality. A feedback annotation travels inside a closed reviewer relationship; it
doesn't broadcast to strangers. The engine is the guest-comment loop + category SEO + a Product Hunt
ignition, not self-spread.

---

## Recommendation

It has legs, as a B2B-first tool that's different from the consumer pitch.

1. **Aim the wedge at ephemeral pages.** AI-generated UIs (the Heurio crowd), A/B variants,
   bug-state-at-time-of-report. That's where "render it as I saw it" is a must-have and where the
   incumbents' anti-snapshot stance becomes their weakness.
2. **Build B2B-first; consumer is the install funnel.** Per-seat $18–25 is where the money is. The
   free tier feeds installs and the guest loop, not direct revenue.
3. **Non-negotiable: zero-install guest view of the archived + annotated snapshot.** This decides
   whether there's a loop or just a tool.
4. **Lead with the snapshot pairing everywhere.** Element-anchored commenting got crowded fast
   (Heurio hit ~30k users in months). The snapshot-permanence pairing is the only defensible
   difference.

Biggest risk is not "does it work" — it's **structural absorption**. A comment + snapshot layer is
exactly what Heurio, BugHerd, or a Figma-style canvas can bolt on. Thin players here exit as
acqui-hires (Pastel → Whatnot at ~$143k revenue), not ARR multiples.

Conflict to name against your own constraints: Pinafly needs a Product Hunt launch and public
founder-led category SEO to ignite. That's at odds with the mbuzz "can't publicly promote, bootstrap,
focused" posture. Decide whether this gets real standalone cycles, or stays the pinnable engine sold
into the people already building feedback tools.

---

## A v1 scope, if it's a go

The smallest thing that tests the wedge, not the whole platform:

- MV3 extension: toggle comment mode, click any element, capture the three anchors + click point
  (port the pinnable anchoring engine).
- Snapshot on capture: self-contained HTML (the SingleFile approach) + a full-page screenshot,
  stored server-side against the pin.
- Hosted snapshot viewer: a teammate opens a link, sees the frozen page re-rendered with numbered
  markers, reads and replies — **no install, no account**.
- @mention → email invite. Threaded replies (the gem already has these).
- Auth + teams + Stripe seats. One free tier, one paid seat tier. Skip the consumer plan until the
  team loop is proven.

Cut for later: public/SEO snapshot pages, browser coverage beyond Chrome, mobile, the AppSumo LTD
(it pads early cash but caps MRR and loads support).

First test to run before any of this: confirm 5–10 people in the ephemeral-page niche (vibe-coding
builders, agencies shipping client review links) would pay for the snapshot specifically. If the
"frozen page" isn't the reason they switch off Heurio, the wedge isn't there.
