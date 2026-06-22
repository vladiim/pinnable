module Pinnable
  # The single seam between the engine and its host. Defaults are safe-off: with no
  # configuration the widget never renders and every endpoint 404s, so a host opts in
  # deliberately rather than by accident.
  class Configuration
    attr_accessor :enabled_for, :current_user, :tenant_scope, :user_label,
      :resolver_label, :parent_controller, :encrypt, :audit, :anchor_max_bytes, :layout

    def initialize
      @enabled_for       = ->(_user) { false }                 # the gate
      @current_user      = ->(_controller) { nil }             # host's auth
      @tenant_scope      = ->(_controller) { nil }             # optional multitenancy
      @user_label        = ->(user) { user.try(:email) || user.try(:name) || user.to_s }
      @resolver_label    = @user_label
      @parent_controller = "ActionController::Base"            # inherit host auth/CSRF/layout
      @encrypt           = false                               # opt-in AR encryption of body/anchor
      @audit             = ->(_pin, _event, _by) {}            # optional sink
      @anchor_max_bytes  = 50_000
      @layout            = "pinnable/application"          # host sets its own for native chrome
    end
  end
end
