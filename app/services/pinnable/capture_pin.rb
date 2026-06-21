module Pinnable
  # Turns a capture payload into a persisted Pin, stamping the author's display label
  # (resolved through the host's `user_label`) so the inbox never needs the host's User.
  class CapturePin
    def initialize(author:, tenant:, params:)
      @author = author
      @tenant = tenant
      @params = params
    end

    def call
      Pin.create!(
        author:,
        tenant:,
        author_label: Pinnable.config.user_label.call(author),
        url: params[:url],
        body: params[:body],
        anchor:
      )
    end

    private

    attr_reader :author, :tenant, :params

    def anchor = (params[:anchor] || {}).to_h
  end
end
