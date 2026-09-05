require "securerandom"

module Kran
  class Git
    def initialize(runner: Kran.runner)
      @runner = runner
    end

    def version
      sha = revision
      uncommitted? ? "#{sha}_uncommitted_#{SecureRandom.hex(8)}" : sha
    end

    private

    def revision
      @runner.capture("git rev-parse HEAD").strip
    rescue CommandFailed => error
      raise Error, "Git could not provide an image tag in #{Dir.pwd}: #{error.message}\n" \
        "Pass --version to set the tag explicitly."
    end

    def uncommitted?
      !@runner.capture("git status --porcelain").strip.empty?
    end
  end
end
