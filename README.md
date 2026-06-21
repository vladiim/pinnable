# Pinnable

Click any element, pin a comment, work it like a task list.

Pinnable is a mountable Rails engine for **in-app visual feedback**. Enable it for some users
(superadmins, your team, a client), they flip a toggle, click **any** element on **any** page, and
leave a note. Each note remembers *who*, *which page*, and *which element* — so it re-anchors on the
next visit and someone else can jump straight to it. Every note is a task: open → resolved, with who
completed it and when.

It's the BugHerd/Marker.io idea, self-hosted, with your data staying in your database.

- **Host-agnostic.** Your auth, your gate, your multitenancy, your audit sink — all injected through
  one config object. The engine assumes none of it.
- **Any database.** Portable schema (no JSONB); proven on SQLite, works on MySQL/Postgres.
- **Hotwire/Stimulus, zero JS dependencies.** One self-contained Stimulus controller; element
  anchoring (CSS selector → XPath → text-quote, tried in order) is hand-rolled, no vendored libs.
- **Test-first.** Model/controller/service tests plus a headless-Chrome system test of the full
  click-to-pin flow.

## Installation

```ruby
# Gemfile
gem "pinnable"
```

```bash
bundle
bin/rails generate pinnable:install
bin/rails pinnable:install:migrations && bin/rails db:migrate
```

Then add the widget to your layout, just before `</body>`:

```erb
<%= pinnable_widget %>
```

## Configuration

`pinnable:install` writes `config/initializers/pinnable.rb`:

```ruby
Pinnable.configure do |c|
  # The gate. Return false → the widget never renders and every endpoint 404s.
  c.enabled_for  = ->(user) { user&.admin? }

  # How to find the current user from a controller.
  c.current_user = ->(controller) { controller.current_user }

  # How a user is labelled in the inbox (no host User object is stored — only this label).
  c.user_label   = ->(user) { user.try(:email) || user.to_s }

  # Engine controllers inherit this, picking up your auth, CSRF, and layout.
  c.parent_controller = "ApplicationController"

  # Optional: scope pins to a tenant (account/org). nil = single-tenant.
  # c.tenant_scope = ->(controller) { controller.current_account }

  # Optional: audit sink for status changes.
  # c.audit = ->(pin, event, by) { Rails.logger.info("pinnable #{event} #{pin.public_id}") }

  # Optional: encrypt body + anchor at rest (needs Active Record encryption configured).
  # c.encrypt = true
end
```

## How it works

- **Capture.** In comment mode a capture-phase click is intercepted (so the underlying control
  doesn't fire) and the clicked element is recorded as three anchors — a CSS selector, an XPath, and
  a `{ prefix, exact, suffix }` text quote — plus a percentage-relative click point.
- **Render.** On each visit the open pins for that path are fetched and re-resolved (css → xpath →
  text-quote, first hit wins) and drawn as numbered markers. If all three miss, the note drops into
  an "unanchored" tray instead of being lost.
- **Work it.** The inbox at `/pinnable` lists every pin, filterable; resolve/reopen stamps who and
  when. A deep link (`/pinnable/pins/:id`) takes anyone to the page with that pin focused.

The widget is the only host touchpoint: `<%= pinnable_widget %>`. Pins are addressed by an opaque
`public_id`, never a raw database id.

## Development

```bash
bin/rails test          # models, controllers, services, generator
bin/rails test:system   # headless-Chrome flow (requires Chrome)
```

The dummy host app under `test/dummy` shows a minimal integration (a `User`, an
`ApplicationController#current_user`, and the `Pinnable.configure` initializer).

## License

MIT.
