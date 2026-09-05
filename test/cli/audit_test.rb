require "cli/cli_test_case"

class AuditTest < CLITestCase
  test "audit shows the rollout history of the app deployments" do
    with_config(BASIC_CONFIG) do
      kran("audit")

      assert_equal ["#{KUBECTL} rollout history deployment -l app=my-app"], runner.commands
    end
  end
end
