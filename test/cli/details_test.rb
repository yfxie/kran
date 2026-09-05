require "cli/cli_test_case"

class DetailsTest < CLITestCase
  test "details lists every resource in the namespace" do
    with_config(BASIC_CONFIG) do
      kran("details")

      assert_equal ["#{KUBECTL} get all -o wide"], runner.commands
    end
  end
end
