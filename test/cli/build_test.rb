require "cli/cli_test_case"

class BuildTest < CLITestCase
  test "build push logs in and builds without deploying" do
    with_config(BASIC_CONFIG) do
      kran("build", "push")

      assert_equal [
        "docker login ghcr.io -u my-user --password-stdin",
        "docker build --platform linux/amd64 --push -t ghcr.io/my-user/my-app:#{SHA} .",
      ], runner.commands
      assert_equal ["s3cret", nil], runner.stdins
    end
  end

  test "build push accepts a version" do
    with_config(BASIC_CONFIG) do
      kran("build", "push", "--version", "v2")

      assert_includes runner.commands.last, ":v2 ."
    end
  end

  test "build push requires docker" do
    runner.executables = []

    with_config(BASIC_CONFIG) do
      assert_match(/\Adocker is not on PATH\./, kran_error("build", "push").message)
    end
  end

  test "build push --dry-run prints the commands without running them" do
    Kran.runner = Kran::Runner.new

    with_config(BASIC_CONFIG) do
      output = kran("build", "push", "--dry-run", "--version", "abc")

      assert_equal <<~OUT, output
      printf '%s' '[REDACTED]' | docker login ghcr.io -u my-user --password-stdin
      docker build --platform linux/amd64 --push -t ghcr.io/my-user/my-app:abc .
    OUT
    end
  end

  test "build details shows the docker daemon and builders in use" do
    with_config(BASIC_CONFIG.sub("arch: amd64", "arch: amd64\n  remote: ssh://build@builder")) do
      kran("build", "details")

      assert_equal ["DOCKER_HOST=ssh://build@builder docker version", "DOCKER_HOST=ssh://build@builder docker buildx ls"],
        runner.commands
    end
  end

  test "build push skips docker login when no credentials are configured" do
    with_config(BASIC_CONFIG.sub("  username: my-user\n  password: s3cret\n", "")) do
      kran("build", "push")

      assert_equal ["docker build --platform linux/amd64 --push -t ghcr.io/my-user/my-app:#{SHA} ."], runner.commands
    end
  end
end
