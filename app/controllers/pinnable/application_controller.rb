# Inherits the host's controller (via config) so it picks up the host's auth, CSRF, and
# layout. Every Pinnable request is gated by the host-supplied `enabled_for` predicate.
class Pinnable::ApplicationController < Pinnable.config.parent_controller.constantize
  before_action :require_pinnable_enabled

  private

  def pinnable_user = @pinnable_user ||= Pinnable.config.current_user.call(self)
  def pinnable_tenant = @pinnable_tenant ||= Pinnable.config.tenant_scope.call(self)

  # Every query starts here: pins are isolated to the host-supplied tenant (a nil tenant
  # means single-tenant — its pins share a null scope and never leak across hosts).
  def pinnable_pins = Pinnable::Pin.where(tenant: pinnable_tenant)

  def require_pinnable_enabled
    head :not_found unless Pinnable.config.enabled_for.call(pinnable_user)
  end
end
