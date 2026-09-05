require "test_helper"

class DependenciesTest < ActiveSupport::TestCase
  test "ensure! passes silently when every tool is on PATH" do
    runner.executables = ["docker", "krane"]

    assert_nil Kran::Dependencies.new.ensure!("docker", "krane")
  end

  test "ensure! names each missing tool with an install hint" do
    runner.executables = ["docker"]

    error = assert_raises(Kran::Error) { Kran::Dependencies.new.ensure!("docker", "krane", "kubectl") }

    assert_equal <<~MESSAGE.chomp, error.message
      krane is not on PATH. Install it with `gem install krane`, or add it to a Gemfile and set krane.command to `bundle exec krane`.
      kubectl is not on PATH. Install it from https://kubernetes.io/docs/tasks/tools/
    MESSAGE
  end

  test "ensure! falls back to a generic hint for other executables" do
    runner.executables = []

    error = assert_raises(Kran::Error) { Kran::Dependencies.new.ensure!("bundle") }

    assert_equal "bundle is not on PATH. Install it and try again.", error.message
  end
end
