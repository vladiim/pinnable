require "test_helper"
require "generators/pinnable/install/install_generator"

class Pinnable::InstallGeneratorTest < Rails::Generators::TestCase
  tests Pinnable::Generators::InstallGenerator
  destination File.expand_path("../../tmp/generator", __dir__)
  setup :prepare_destination

  setup do
    mkdir_p "#{destination_root}/config"
    File.write("#{destination_root}/config/routes.rb", "Rails.application.routes.draw do\nend\n")
  end

  test "writes an initializer carrying the config seam" do
    run_generator

    assert_file "config/initializers/pinnable.rb" do |content|
      assert_match "Pinnable.configure", content
      assert_match "enabled_for", content
      assert_match "current_user", content
      assert_match "parent_controller", content
    end
  end

  test "mounts the engine in the host routes" do
    run_generator

    assert_file "config/routes.rb", %r{mount Pinnable::Engine => "/pinnable"}
  end
end
