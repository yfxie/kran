require "cli/cli_test_case"

class DeployTest < CLITestCase
  IMAGE = "ghcr.io/my-user/my-app"

  test "deploy logs in, builds and pushes, then renders into krane deploy" do
    with_config(BASIC_CONFIG, "config/deploy/secrets.ejson" => "{}") do
      kran("deploy")

      assert_equal [
        "docker login ghcr.io -u my-user --password-stdin",
        "docker build --platform linux/amd64 --push -t #{IMAGE}:#{SHA} .",
        "krane render -f config/deploy --current-sha #{SHA} --bindings image=#{IMAGE}:#{SHA} | " \
          "KUBECONFIG=#{File.expand_path("~/.kube/my-cluster.yml")} krane deploy my-app my-cluster " \
          "-f config/deploy/secrets.ejson -",
      ], runner.commands
      assert_equal ["s3cret", nil, nil], runner.stdins
    end
  end

  test "deploy uses the given version as the image tag" do
    with_config(BASIC_CONFIG) do
      kran("deploy", "--version", "v1.2.3")

      assert_includes runner.commands[1], "-t #{IMAGE}:v1.2.3 "
      assert_includes runner.commands[2], "--current-sha v1.2.3 --bindings image=#{IMAGE}:v1.2.3"
    end
  end

  test "deploy tags uncommitted changes" do
    runner.captures["git status --porcelain"] = " M app.rb\n"

    with_config(BASIC_CONFIG) do
      kran("deploy")

      assert_match(/-t #{IMAGE}:#{SHA}_uncommitted_[0-9a-f]{16} /, runner.commands[1])
    end
  end

  test "deploy -P skips login, build and push" do
    with_config(BASIC_CONFIG) do
      kran("deploy", "-P")

      assert_equal 1, runner.commands.size
      assert_match(/\Akrane render/, runner.commands.first)
    end
  end

  test "deploy fails with guidance outside a git repository" do
    runner.captures.clear

    with_config(BASIC_CONFIG) do
      error = kran_error("deploy")

      assert_match(/\AGit could not provide an image tag/, error.message)
      assert_empty runner.commands
    end
  end

  test "deploy --dry-run prints the commands without running them" do
    Kran.runner = Kran::Runner.new

    with_config(BASIC_CONFIG.sub("  kubeconfig: ~/.kube/my-cluster.yml\n", "")) do
      output = kran("deploy", "--dry-run", "--version", "abc")

      assert_equal <<~OUT, output
        printf '%s' '[REDACTED]' | docker login ghcr.io -u my-user --password-stdin
        docker build --platform linux/amd64 --push -t #{IMAGE}:abc .
        krane render -f config/deploy --current-sha abc --bindings image=#{IMAGE}:abc | krane deploy my-app my-cluster -f -
      OUT
    end
  end

  test "deploy checks for docker, krane and kubectl before running anything" do
    runner.executables = ["docker", "kubectl"]

    with_config(BASIC_CONFIG) do
      error = kran_error("deploy")

      assert_match(/\Akrane is not on PATH\./, error.message)
      assert_empty runner.commands
    end
  end

  test "deploy -P does not need docker" do
    runner.executables = ["krane", "kubectl"]

    with_config(BASIC_CONFIG) do
      kran("deploy", "-P")

      assert_equal 1, runner.commands.size
    end
  end

  test "deploy checks the executable behind krane.command" do
    runner.executables = ["docker", "krane", "kubectl"]

    with_config(BASIC_CONFIG + "krane:\n  command: bundle exec krane\n") do
      error = kran_error("deploy")

      assert_equal "bundle is not on PATH. Install it and try again.", error.message
    end
  end

  test "deploy reads the destination config" do
    with_config(BASIC_CONFIG, "config/kran.staging.yml" => "kubernetes:\n  namespace: my-app-staging\n") do
      kran("deploy", "-d", "staging", "-P")

      assert_includes runner.commands.first, "krane deploy my-app-staging my-cluster"
    end
  end
end
