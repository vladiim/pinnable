require "test_helper"

class Pinnable::MarkersControllerTest < ActionDispatch::IntegrationTest
  MARKERS = "/pinnable/markers".freeze

  test "returns the open pins for a page so the overlay can render them" do
    here  = pin_on("/dashboard", "fix this")
    pin_on("/dashboard", "and this")
    pin_on("/other", "elsewhere")            # different page — excluded
    here.resolved!                            # resolved — excluded

    get MARKERS, params: { url: "/dashboard" }, headers: as(admin)

    assert_response :success
    bodies = json.map { |m| m["body"] }
    assert_equal ["and this"], bodies
    assert_equal "#totals .amount", json.first["anchor"]["css"]
    assert_equal "admin@example.com", json.first["author_label"]
    assert json.first["public_id"].present?
  end

  test "markers carry a pin's reply thread" do
    pin = pin_on("/dashboard", "needs a fix")
    pin.comments.create!(author: admin, author_label: admin.email, body: "looking now")

    get MARKERS, params: { url: "/dashboard" }, headers: as(admin)

    assert_equal [ "looking now" ], json.first["comments"].map { |c| c["body"] }
    assert_equal "admin@example.com", json.first["comments"].first["author_label"]
  end

  test "a user the gate rejects gets 404" do
    get MARKERS, params: { url: "/dashboard" }, headers: as(member)
    assert_response :not_found
  end

  private

  def pin_on(url, body)
    Pinnable::Pin.create!(url:, body:, author: admin, author_label: admin.email,
      anchor: { "css" => "#totals .amount" })
  end

  def json   = @json ||= JSON.parse(response.body)
  def as(u)  = { "X-Test-User-Id" => u.id.to_s }
  def admin  = @admin  ||= User.create!(email: "admin@example.com", admin: true)
  def member = @member ||= User.create!(email: "member@example.com", admin: false)
end
