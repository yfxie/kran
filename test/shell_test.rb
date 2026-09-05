require "test_helper"

class ShellTest < ActiveSupport::TestCase
  test "escape leaves plain words, selectors and paths bare" do
    assert_equal "app=my-app", Kran::Shell.escape("app=my-app")
    assert_equal "ghcr.io/my-user/my-app:abc", Kran::Shell.escape("ghcr.io/my-user/my-app:abc")
  end

  test "escape single-quotes anything else" do
    assert_equal "'puts 1'", Kran::Shell.escape("puts 1")
    assert_equal "'it'\\''s'", Kran::Shell.escape("it's")
    assert_equal "''", Kran::Shell.escape("")
  end

  test "join escapes each word" do
    assert_equal "kubectl exec -- 'bin/rails runner' x", Kran::Shell.join(["kubectl", "exec", "--", "bin/rails runner", "x"])
  end
end
