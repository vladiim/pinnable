require "test_helper"

# The dummy host opts into encryption (config.encrypt = true). A note or text-quote can
# carry PII (e.g. a person's name on the page), so both must be ciphertext at rest.
class Pinnable::PinEncryptionTest < ActiveSupport::TestCase
  test "body and anchor are encrypted at rest but round-trip in the clear" do
    pin = Pinnable::Pin.create!(url: "/x", body: "Jane Smith is late",
      anchor: { "css" => "#name", "exact" => "Jane Smith" })

    raw = Pinnable::Pin.connection.select_one("SELECT body, anchor FROM pinnable_pins WHERE id = #{pin.id}")
    refute_includes raw["body"].to_s, "Jane Smith"
    refute_includes raw["anchor"].to_s, "Jane Smith"

    pin.reload
    assert_equal "Jane Smith is late", pin.body
    assert_equal "Jane Smith", pin.anchor["exact"]
    assert_equal "#name", pin.anchor["css"]
  end
end
