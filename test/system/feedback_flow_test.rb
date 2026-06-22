require "application_system_test_case"

class FeedbackFlowTest < ApplicationSystemTestCase
  setup { @admin = User.create!(email: "admin@example.com", admin: true) }

  test "toggle comment mode, click an element, leave feedback, and it persists and re-renders" do
    sign_in_and_visit_dashboard
    assert_no_selector ".pinnable-marker"

    find(".pinnable-toggle").click
    assert_text "Comments: On"

    find("#amount").click
    find(".pinnable-composer__text").set("the total looks wrong")
    find(".pinnable-composer__save").click

    assert_selector ".pinnable-marker"
    pin = Pinnable::Pin.last
    assert_equal "the total looks wrong", pin.body
    assert_equal "/dashboard", pin.url
    assert_includes pin.anchor["css"], "amount"

    visit "/dashboard"
    assert_selector ".pinnable-marker", count: 1
  end

  test "reply to a pin from its popover" do
    sign_in_and_visit_dashboard

    find(".pinnable-toggle").click
    find("#amount").click
    find(".pinnable-composer__text").set("the total looks wrong")
    find(".pinnable-composer__save").click
    assert_selector ".pinnable-marker"

    find(".pinnable-toggle").click # comments off — now click the pin to read/reply
    find(".pinnable-marker").click
    assert_selector ".pinnable-pop"
    find(".pinnable-pop__input").set("on it now")
    find(".pinnable-pop__input").native.send_keys(:return)

    assert_selector ".pinnable-pop__comment", text: "on it now"
    assert_equal 1, Pinnable::Comment.count
    assert_equal "on it now", Pinnable::Comment.last.body
  end

  test "a non-admin never sees the widget" do
    member = User.create!(email: "member@example.com", admin: false)
    visit "/sign_in/#{member.id}"
    assert_no_selector ".pinnable-toggle"
  end

  private

  def sign_in_and_visit_dashboard
    visit "/sign_in/#{@admin.id}"
    assert_text "Dashboard"
  end
end
