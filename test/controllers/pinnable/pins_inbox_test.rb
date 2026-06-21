require "test_helper"

class Pinnable::PinsInboxTest < ActionDispatch::IntegrationTest
  test "the inbox lists every pin for the tenant" do
    Pinnable::Pin.create!(url: "/a", body: "first note", author: admin, author_label: admin.email, anchor: {})
    Pinnable::Pin.create!(url: "/b", body: "second note", author: admin, author_label: admin.email, anchor: {})

    get "/pinnable/pins", headers: as(admin)

    assert_response :success
    assert_includes response.body, "first note"
    assert_includes response.body, "second note"
  end

  test "the inbox is gated" do
    get "/pinnable/pins", headers: as(member)
    assert_response :not_found
  end

  test "opening a pin deep-links to its page with the pin focused" do
    pin = Pinnable::Pin.create!(url: "/dashboard", body: "x", author: admin, author_label: admin.email, anchor: {})

    get "/pinnable/pins/#{pin.public_id}", headers: as(admin)

    assert_redirected_to "/dashboard?pinnable=#{pin.public_id}"
  end

  private

  def as(u) = { "X-Test-User-Id" => u.id.to_s }
  def admin  = @admin  ||= User.create!(email: "admin@example.com", admin: true)
  def member = @member ||= User.create!(email: "member@example.com", admin: false)
end
