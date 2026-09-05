require "cli/cli_test_case"

class ExecTest < CLITestCase
  test "exec runs the command in a running app pod" do
    with_config(BASIC_CONFIG) do
      kran("exec", "bin/rails", "db:migrate")

      assert_equal 1, runner.commands.size
      assert_match(/\Apod=\$\(#{Regexp.escape(KUBECTL)} get pods -l app=my-app/, runner.commands.first)
      assert_match(/#{Regexp.escape(KUBECTL)} exec "\$pod" -- bin\/rails db:migrate\z/, runner.commands.first)
    end
  end

  test "exec --interactive allocates a tty" do
    with_config(BASIC_CONFIG) do
      kran("exec", "-i", "bash")

      assert_match(/exec -it "\$pod" -- bash\z/, runner.commands.first)
    end
  end

  test "exec keeps flags after -- for the command" do
    with_config(BASIC_CONFIG) do
      kran("exec", "--", "bin/rails", "runner", "-e", "production", "puts 1")

      assert_match(/-- bin\/rails runner -e production 'puts 1'\z/, runner.commands.first)
    end
  end

  test "exec needs a command" do
    with_config(BASIC_CONFIG) do
      assert_equal "exec needs a command to run, for example `kran exec bin/rails db:migrate`",
        kran_error("exec").message
    end
  end
end
