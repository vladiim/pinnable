module Pinnable
  class Engine < ::Rails::Engine
    isolate_namespace Pinnable

    # Expose the host-facing helper (`<%= pinnable_widget %>`) in the host's views,
    # regardless of the host's `include_all_helpers` setting.
    initializer "pinnable.helpers" do
      ActiveSupport.on_load(:action_controller_base) { helper Pinnable::WidgetHelper }
    end

    # Merge the engine's pins into the host import map so `import "pinnable"` resolves.
    # No-op on hosts that don't use importmap-rails (they include the asset themselves).
    initializer "pinnable.importmap", before: "importmap" do |app|
      next unless app.config.respond_to?(:importmap)

      app.config.importmap.paths << root.join("config/importmap.rb")
      app.config.importmap.cache_sweepers << root.join("app/assets/javascripts")
    end
  end
end
