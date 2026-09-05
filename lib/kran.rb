require "English"
require "kran/version"

module Kran
  class Error < StandardError; end

  class << self
    attr_writer :runner

    def runner
      @runner ||= Runner.new
    end
  end
end

require "kran/shell"
require "kran/runner"
require "kran/ejson"
require "kran/git"
require "kran/configuration"
require "kran/commands/docker"
require "kran/commands/krane"
require "kran/commands/kubectl"
require "kran/dependencies"
require "kran/cli"
