# How a host wires Pinnable. Everything app-specific lives here; the engine assumes none of it.
Pinnable.configure do |c|
  c.parent_controller = "ApplicationController"          # inherit host auth/CSRF/layout
  c.current_user      = ->(controller) { controller.current_user }
  c.enabled_for       = ->(user) { user&.admin? }        # the gate
  c.user_label        = ->(user) { user.email }
  c.encrypt           = true                             # encrypt body + anchor at rest
end
