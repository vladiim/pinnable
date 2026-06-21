require "rails/generators/base"

module Pinnable
  module Generators
    # `rails generate pinnable:install` — drops the config initializer and mounts the
    # engine. Migrations are installed separately via `rails pinnable:install:migrations`
    # (the standard engine task), kept out of here so the schema stays single-sourced.
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      def create_initializer
        template "pinnable.rb", "config/initializers/pinnable.rb"
      end

      def mount_engine
        route 'mount Pinnable::Engine => "/pinnable"'
      end

      def show_post_install
        say ""
        say "Pinnable installed. Two steps left:", :green
        say "  1. bin/rails pinnable:install:migrations && bin/rails db:migrate"
        say "  2. Add <%= pinnable_widget %> to your layout, just before </body>."
      end
    end
  end
end
