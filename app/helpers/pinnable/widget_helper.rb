module Pinnable
  # The single host-facing entry point: drop `<%= pinnable_widget %>` in the layout.
  # Renders nothing unless the host's gate says this user may give feedback.
  module WidgetHelper
    def pinnable_widget
      return unless Pinnable.config.enabled_for.call(Pinnable.config.current_user.call(controller))

      render "pinnable/widget"
    end
  end
end
