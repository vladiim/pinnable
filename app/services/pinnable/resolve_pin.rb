module Pinnable
  # Moves a pin along its task lifecycle (open -> resolved/wont_fix and back), stamping
  # who completed it and when, then emitting the host's audit event. Reopening clears
  # the completion stamps so the task reads as live again.
  class ResolvePin
    COMPLETED = %w[resolved wont_fix].freeze

    def initialize(pin:, by:, status:)
      @pin = pin
      @by = by
      @status = status.to_s
    end

    def call
      pin.update!(status:, **completion)
      Pinnable.config.audit.call(pin, status.to_sym, by)
      pin
    end

    private

    attr_reader :pin, :by, :status

    def completion
      return { resolved_by: nil, resolved_by_label: nil, resolved_at: nil } unless completed?

      { resolved_by: by, resolved_by_label: Pinnable.config.resolver_label.call(by), resolved_at: Time.current }
    end

    def completed? = COMPLETED.include?(status)
  end
end
