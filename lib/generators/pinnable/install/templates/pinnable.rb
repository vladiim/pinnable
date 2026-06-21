# Pinnable configuration. Everything app-specific lives here; the engine assumes none of it.
Pinnable.configure do |c|
  # The gate. Return false and the widget never renders and every endpoint 404s.
  c.enabled_for = ->(user) { user&.admin? }

  # How to find the current user from a controller (whatever your auth uses).
  c.current_user = ->(controller) { controller.current_user }

  # How to label a user in the inbox. No host User object is stored — only this label.
  c.user_label = ->(user) { user.try(:email) || user.try(:name) || user.to_s }

  # Engine controllers inherit this, picking up your auth, CSRF, and layout.
  c.parent_controller = "ApplicationController"

  # Optional: scope pins to a tenant (account/org). Return nil for a single-tenant app.
  # c.tenant_scope = ->(controller) { controller.current_account }

  # Optional: a sink for status changes (open -> resolved/wont_fix and back).
  # c.audit = ->(pin, event, by) { Rails.logger.info("pinnable #{event} #{pin.public_id}") }

  # Optional: encrypt body + anchor at rest (requires Active Record encryption configured).
  # c.encrypt = true
end
