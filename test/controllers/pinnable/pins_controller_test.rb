require "test_helper"

class Pinnable::PinsControllerTest < ActionDispatch::IntegrationTest
  PINS = "/pinnable/pins".freeze

  test "an enabled user pins feedback on an element and it persists" do
    assert_difference -> { Pinnable::Pin.count }, 1 do
      post PINS, params: pin_params, headers: as(admin), as: :json
    end

    assert_response :success
    assert_equal "/dashboard",             pin.url
    assert_equal "this label is wrong",    pin.body
    assert_equal "#totals .amount",        pin.anchor["css"]
    assert_equal "Total",                  pin.anchor["text_exact"]
    assert_equal "admin@example.com",      pin.author_label
    assert_equal admin,                    pin.author
    assert pin.open?
    assert pin.public_id.present?
  end

  test "a user the gate rejects cannot pin and gets 404" do
    assert_no_difference -> { Pinnable::Pin.count } do
      post PINS, params: pin_params, headers: as(member), as: :json
    end

    assert_response :not_found
  end

  test "an anonymous request cannot pin and gets 404" do
    post PINS, params: pin_params, as: :json
    assert_response :not_found
  end

  private

  def pin_params
    {
      pin: {
        url: "/dashboard",
        body: "this label is wrong",
        anchor: { css: "#totals .amount", text_exact: "Total" }
      }
    }
  end

  def as(user) = { "X-Test-User-Id" => user.id.to_s }
  def pin      = @pin ||= Pinnable::Pin.last
  def admin    = @admin  ||= User.create!(email: "admin@example.com", admin: true)
  def member   = @member ||= User.create!(email: "member@example.com", admin: false)
end
