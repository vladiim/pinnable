require "pinnable/version"
require "pinnable/configuration"
require "pinnable/engine"

# Pinnable — a host-agnostic, mountable visual-feedback layer. Enable it for some
# users, flip a toggle, click any element on any page, leave a note. Notes remember
# who/where/which-element, re-anchor on reload, and are worked like a task list.
#
# Everything the host differs on — auth, the gate, multitenancy, the audit sink — is
# injected through `Pinnable.config`, so the engine carries no app-specific coupling.
module Pinnable
  class << self
    def config = @config ||= Configuration.new
    def configure = yield config
    def reset_config! = @config = Configuration.new
  end
end
