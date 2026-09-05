module Kran
  class Dependencies
    HINTS = {
      "docker" => "Install it from https://docs.docker.com/get-docker/",
      "krane" => "Install it with `gem install krane`, or add it to a Gemfile and set krane.command to " \
        "`bundle exec krane`.",
      "kubectl" => "Install it from https://kubernetes.io/docs/tasks/tools/",
      "ejson" => "Install it with `gem install ejson` (krane depends on it) or `brew install ejson`.",
    }.freeze
    GENERIC_HINT = "Install it and try again."

    def initialize(runner: Kran.runner)
      @runner = runner
    end

    def ensure!(*names)
      missing = names.reject { |name| @runner.executable?(name) }
      return if missing.empty?

      raise Error, missing.map { |name| "#{name} is not on PATH. #{HINTS.fetch(name, GENERIC_HINT)}" }.join("\n")
    end
  end
end
