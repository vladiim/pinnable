# Changelog

## [0.1.0] — 2026-06-22

Initial release.

- Mountable Rails engine for in-app visual feedback — enable it for some users, toggle comment
  mode, click any DOM element, leave a note.
- **Anchoring with zero JS dependencies**: each pin stores a CSS selector, XPath, and text-quote;
  re-resolves in order so the pin survives DOM drift, with an "unanchored" tray when it can't.
- **Task management**: pins move open → resolved → won't-fix, stamped with resolver + timestamp.
- **Polished, self-contained inbox** (own layout + scoped CSS), with deep-link "open on page".
- **Reply threads** on a pin — on-page popover and inbox reply count.
- **Host-agnostic config seam**: `enabled_for`, `current_user`, `tenant_scope`, `user_label`,
  `parent_controller`, `layout`, `audit`, `encrypt`.
- **Optional at-rest encryption** of `body` + `anchor` via Active Record encryption.
- **Any database** — portable schema, no JSONB.
- Hotwire/Stimulus, delivered via importmap merge. `pinnable:install` generator.
