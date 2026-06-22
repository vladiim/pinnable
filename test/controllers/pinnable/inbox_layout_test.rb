require "test_helper"

# Hosts render the inbox in their own chrome by setting `config.layout`.
class Pinnable::InboxLayoutTest < ActionDispatch::IntegrationTest
  setup { @prev = Pinnable.config.layout }
  teardown { Pinnable.config.layout = @prev }

  test "the inbox renders within the host-configured layout" do
    Pinnable.config.layout = "alt"

    get "/pinnable/pins", headers: { "X-Test-User-Id" => admin.id.to_s }

    assert_response :success
    assert_includes response.body, "ALT-LAYOUT-MARKER"
  end

  private

  def admin = @admin ||= User.create!(email: "admin@example.com", admin: true)
end
