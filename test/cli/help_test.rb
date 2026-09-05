require "cli/cli_test_case"

class HelpTest < CLITestCase
  test "help lists every command" do
    output = kran("--help")

    ["init", "deploy", "build", "logs", "exec", "details", "audit", "version"].each do |command|
      assert_match(/^  kran #{command}\b/, output)
    end
  end

  test "help lists the build subcommands" do
    output = kran("build", "--help")

    assert_match(/^  kran build push\b/, output)
    assert_match(/^  kran build details\b/, output)
  end
end
