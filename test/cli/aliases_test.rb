require "cli/cli_test_case"

class AliasesTest < CLITestCase
  ALIASES = "aliases:\n  shell: exec --interactive bash\n  migrate: exec bin/rails db:migrate\n"

  test "an alias expands to its command" do
    with_config(BASIC_CONFIG + ALIASES) do
      kran("shell")

      assert_match(/exec -it "\$pod" -- bash\z/, runner.commands.first)
    end
  end

  test "an alias keeps the extra arguments" do
    with_config(BASIC_CONFIG + ALIASES) do
      kran("migrate", "--trace")

      assert_match(/-- bin\/rails db:migrate --trace\z/, runner.commands.first)
    end
  end

  test "an alias honours the destination" do
    staging = "kubernetes:\n  namespace: my-app-staging\n"
    with_config(BASIC_CONFIG + ALIASES, "config/kran.staging.yml" => staging) do
      kran("shell", "-d", "staging")

      assert_includes runner.commands.first, "--namespace my-app-staging"
    end
  end

  test "an unknown command is still reported" do
    with_config(BASIC_CONFIG + ALIASES) do
      _, stderr = capture_io { assert_raises(SystemExit) { Kran::CLI::Main.start(["nope"]) } }

      assert_includes stderr, 'Could not find command "nope"'
    end
  end
end
