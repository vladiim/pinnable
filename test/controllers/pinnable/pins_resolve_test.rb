require "test_helper"

class Pinnable::PinsResolveTest < ActionDispatch::IntegrationTest
  setup do
    @events = []
    @prev_audit = Pinnable.config.audit
    Pinnable.config.audit = ->(pin, event, by) { @events << [event, by, pin.public_id] }
  end

  teardown { Pinnable.config.audit = @prev_audit }

  test "resolving a pin records who completed it, when, and audits it" do
    patch path(pin), params: status("resolved"), headers: as(admin), as: :json

    assert_response :success
    pin.reload
    assert pin.resolved?
    assert_equal admin, pin.resolved_by
    assert_equal "admin@example.com", pin.resolved_by_label
    assert pin.resolved_at.present?
    assert_equal [:resolved, admin, pin.public_id], @events.last
  end

  test "reopening a resolved pin clears the completion stamps" do
    pin.update!(status: :resolved, resolved_by: admin, resolved_by_label: admin.email, resolved_at: Time.current)

    patch path(pin), params: status("open"), headers: as(admin), as: :json

    pin.reload
    assert pin.open?
    assert_nil pin.resolved_by
    assert_nil pin.resolved_at
  end

  test "the gate blocks resolving and leaves the pin untouched" do
    patch path(pin), params: status("resolved"), headers: as(member), as: :json

    assert_response :not_found
    assert pin.reload.open?
  end

  private

  def path(pin) = "/pinnable/pins/#{pin.public_id}"
  def status(value) = { pin: { status: value } }
  def as(u) = { "X-Test-User-Id" => u.id.to_s }

  def pin
    @pin ||= Pinnable::Pin.create!(url: "/dashboard", body: "fix", author: admin,
      author_label: admin.email, anchor: { "css" => "#x" })
  end

  def admin  = @admin  ||= User.create!(email: "admin@example.com", admin: true)
  def member = @member ||= User.create!(email: "member@example.com", admin: false)
end
