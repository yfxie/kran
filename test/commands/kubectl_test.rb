require "test_helper"

class KubectlCommandsTest < ActiveSupport::TestCase
  KUBECTL = "KUBECONFIG=#{File.expand_path("~/.kube/my-cluster.yml")} kubectl --context my-cluster --namespace my-app"

  test "logs tails the selected pods with the given options" do
    with_config(BASIC_CONFIG) do
      assert_equal "#{KUBECTL} logs -l app=my-app --prefix --timestamps --tail 100", kubectl.logs(lines: 100)
      assert_equal "#{KUBECTL} logs -l app=my-app --prefix --timestamps --tail 20 --since 1h -f | grep ERROR",
        kubectl.logs(lines: 20, since: "1h", follow: true, grep: "ERROR")
    end
  end

  test "logs and exec target the configured container" do
    with_config(BASIC_CONFIG.sub("selector: app=my-app", "selector: app=my-app\n  container: web")) do
      assert_equal "#{KUBECTL} logs -l app=my-app -c web --prefix --timestamps --tail 100", kubectl.logs(lines: 100)
      assert_includes kubectl.exec(["ls"]), %(exec "$pod" -c web -- ls)
    end
  end

  test "exec looks up a running pod and runs the command in it" do
    with_config(BASIC_CONFIG) do
      expected = <<~SH.chomp
        pod=$(#{KUBECTL} get pods -l app=my-app --field-selector status.phase=Running -o 'jsonpath={.items[0].metadata.name}') && test -n "$pod" || { echo 'No running pod matches app=my-app' >&2; exit 1; }
        #{KUBECTL} exec "$pod" -- bin/rails runner 'puts 1'
      SH

      assert_equal expected, kubectl.exec(["bin/rails", "runner", "puts 1"])
    end
  end

  test "exec allocates a tty when interactive" do
    with_config(BASIC_CONFIG) do
      assert_includes kubectl.exec(["bash"], interactive: true), %(exec -it "$pod" -- bash)
    end
  end

  test "details lists everything in the namespace" do
    with_config(BASIC_CONFIG) do
      assert_equal "#{KUBECTL} get all -o wide", kubectl.details
    end
  end

  test "audit shows the rollout history of the selected deployments" do
    with_config(BASIC_CONFIG) do
      assert_equal "#{KUBECTL} rollout history deployment -l app=my-app", kubectl.audit
    end
  end

  test "commands leave out KUBECONFIG when it is not configured" do
    with_config(BASIC_CONFIG.sub("  kubeconfig: ~/.kube/my-cluster.yml\n", "")) do
      assert_equal "kubectl --context my-cluster --namespace my-app get all -o wide", kubectl.details
    end
  end

  private

  def kubectl
    Kran::Commands::Kubectl.new(Kran::Configuration.load)
  end
end
