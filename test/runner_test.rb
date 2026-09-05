require "test_helper"

class RunnerTest < ActiveSupport::TestCase
  test "run prints the command and executes it through the shell" do
    Dir.mktmpdir do |dir|
      runner = Kran::Runner.new

      output, = capture_io { runner.run("touch #{dir}/made && echo done") }

      assert_equal "touch #{dir}/made && echo done\n", output
      assert_path_exists "#{dir}/made"
    end
  end

  test "run feeds stdin to the command and prints it redacted" do
    Dir.mktmpdir do |dir|
      runner = Kran::Runner.new

      output, = capture_io { runner.run("cat > #{dir}/secret", stdin: "hunter2") }

      assert_equal "printf '%s' '[REDACTED]' | cat > #{dir}/secret\n", output
      assert_equal "hunter2", File.read("#{dir}/secret")
    end
  end

  test "run raises when the command fails" do
    runner = Kran::Runner.new

    error = assert_raises(Kran::CommandFailed) do
      capture_io { runner.run("exit 3") }
    end

    assert_equal "Command failed (exit 3): exit 3", error.message
  end

  test "run only prints when dry_run is on" do
    Dir.mktmpdir do |dir|
      runner = Kran::Runner.new(dry_run: true)

      output, = capture_io { runner.run("touch #{dir}/made", stdin: "x") }

      assert_equal "printf '%s' '[REDACTED]' | touch #{dir}/made\n", output
      refute_path_exists "#{dir}/made"
    end
  end

  test "capture returns stdout without printing" do
    runner = Kran::Runner.new

    result = nil
    output, = capture_io { result = runner.capture("printf hello") }

    assert_equal "hello", result
    assert_equal "", output
  end

  test "capture raises with stderr when the command fails" do
    runner = Kran::Runner.new

    error = assert_raises(Kran::CommandFailed) { runner.capture("echo oops >&2; exit 1") }

    assert_equal "Command failed (exit 1): echo oops >&2; exit 1\noops", error.message
  end

  test "capture reports a missing executable as a failed command" do
    runner = Kran::Runner.new

    error = assert_raises(Kran::CommandFailed) { runner.capture("definitely-not-a-tool --version") }

    assert_equal "Command failed: definitely-not-a-tool --version\nNo such file or directory - definitely-not-a-tool",
      error.message
  end

  test "commands run outside the bundler environment of kran itself" do
    runner = Kran::Runner.new

    assert_equal "\n", runner.capture("echo $BUNDLE_GEMFILE$RUBYOPT")
  end

  test "executable? looks the name up on PATH" do
    Dir.mktmpdir do |dir|
      File.write("#{dir}/mytool", "#!/bin/sh\n")
      File.chmod(0o755, "#{dir}/mytool")
      runner = Kran::Runner.new

      with_path(dir) do
        assert runner.executable?("mytool")
        refute runner.executable?("othertool")
      end
    end
  end

  private

  def with_path(dir)
    original = ENV.fetch("PATH")
    ENV["PATH"] = dir
    yield
  ensure
    ENV["PATH"] = original
  end
end
