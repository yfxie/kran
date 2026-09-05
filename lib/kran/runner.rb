require "open3"

module Kran
  class CommandFailed < Error; end

  class Runner
    attr_accessor :dry_run

    def initialize(dry_run: false)
      @dry_run = dry_run
    end

    def run(command, stdin: nil)
      puts(stdin ? "printf '%s' '[REDACTED]' | #{command}" : command)
      return if dry_run

      status = unbundled { execute(command, stdin) }
      raise CommandFailed, "Command failed (exit #{status.exitstatus}): #{command}" unless status.success?
    end

    def capture(command)
      stdout, stderr, status = unbundled { Open3.capture3(command) }
      unless status.success?
        raise CommandFailed, "Command failed (exit #{status.exitstatus}): #{command}\n#{stderr.strip}"
      end

      stdout
    rescue Errno::ENOENT => error
      raise CommandFailed, "Command failed: #{command}\n#{error.message}"
    end

    def executable?(name)
      ENV.fetch("PATH").split(File::PATH_SEPARATOR).any? { |dir| File.executable?(File.join(dir, name)) }
    end

    private

    def execute(command, stdin)
      if stdin
        IO.popen(command, "w") { |io| io.write(stdin) }
      else
        system(command)
      end
      $CHILD_STATUS
    end

    # kran is usually started through `bundle exec` or a binstub, and the tools it
    # drives (krane, ejson) are Ruby programs of their own. Without this they would
    # inherit RUBYOPT and BUNDLE_GEMFILE and refuse to start unless they happened to
    # be in the same bundle as kran.
    def unbundled(&block)
      defined?(Bundler) ? Bundler.with_unbundled_env(&block) : yield
    end
  end
end
