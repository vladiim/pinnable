require "test_helper"

class Pinnable::CommentsControllerTest < ActionDispatch::IntegrationTest
  test "an enabled user replies to a pin" do
    pin = create_pin

    assert_difference -> { Pinnable::Comment.count }, 1 do
      post "/pinnable/pins/#{pin.public_id}/comments",
        params: { comment: { body: "on it" } }, headers: as(admin), as: :json
    end

    assert_response :success
    comment = Pinnable::Comment.last
    assert_equal pin,                 comment.pin
    assert_equal "on it",             comment.body
    assert_equal admin,               comment.author
    assert_equal "admin@example.com", comment.author_label
  end

  test "the gate blocks replies" do
    pin = create_pin

    assert_no_difference -> { Pinnable::Comment.count } do
      post "/pinnable/pins/#{pin.public_id}/comments",
        params: { comment: { body: "x" } }, headers: as(member), as: :json
    end

    assert_response :not_found
  end

  test "a reply is scoped to the tenant's pins" do
    pin = create_pin

    assert_difference -> { Pinnable::Comment.count }, 1 do
      post "/pinnable/pins/#{pin.public_id}/comments",
        params: { comment: { body: "scoped" } }, headers: as(admin), as: :json
    end
  end

  private

  def create_pin = Pinnable::Pin.create!(url: "/x", body: "b", author: admin, author_label: admin.email, anchor: {})
  def as(u) = { "X-Test-User-Id" => u.id.to_s }
  def admin  = @admin  ||= User.create!(email: "admin@example.com", admin: true)
  def member = @member ||= User.create!(email: "member@example.com", admin: false)
end
