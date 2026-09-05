require "cli/cli_test_case"

class LogsTest < CLITestCase
  test "logs shows recent lines from the app pods" do
    with_config(BASIC_CONFIG) do
      kran("logs")

      assert_equal ["#{KUBECTL} logs -l app=my-app --prefix --timestamps"], runner.commands
    end
  end

  test "logs passes lines, since, grep and follow through" do
    with_config(BASIC_CONFIG) do
      kran("logs", "-n", "50", "--since", "10m", "-g", "ERROR", "-f")

      assert_equal ["#{KUBECTL} logs -l app=my-app --prefix --timestamps --tail 50 --since 10m -f | grep ERROR"],
        runner.commands
    end
  end

  test "logs requires kubectl" do
    runner.executables = []

    with_config(BASIC_CONFIG) do
      assert_match(/\Akubectl is not on PATH\./, kran_error("logs").message)
    end
  end
end
