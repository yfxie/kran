require "test_helper"

class GitTest < ActiveSupport::TestCase
  SHA = "3f2a9c0d8e7b6a5f4e3d2c1b0a9f8e7d6c5b4a39"

  test "version is the HEAD sha when the working tree is clean" do
    runner.captures.merge!("git rev-parse HEAD" => "#{SHA}\n", "git status --porcelain" => "")

    assert_equal SHA, Kran::Git.new.version
  end

  test "version carries an _uncommitted_ suffix when the working tree is dirty" do
    runner.captures.merge!("git rev-parse HEAD" => "#{SHA}\n", "git status --porcelain" => " M lib/app.rb\n")

    assert_match(/\A#{SHA}_uncommitted_[0-9a-f]{16}\z/, Kran::Git.new.version)
  end

  test "version fails with guidance outside a git repository" do
    error = assert_raises(Kran::Error) { Kran::Git.new.version }

    assert_match(/\AGit could not provide an image tag in #{Regexp.escape(Dir.pwd)}/, error.message)
    assert_match(/Pass --version to set the tag explicitly\.\z/, error.message)
  end
end
