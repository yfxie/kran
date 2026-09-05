require "cli/cli_test_case"

class VersionTest < CLITestCase
  test "version lists kran and every tool it drives" do
    runner.captures.merge!(
      "docker --version" => "Docker version 27.0.3, build 7d4bcd8\n",
      "krane version" => "krane 3.9.1\n",
      "kubectl version --client" => "Client Version: v1.31.0\nKustomize Version: v5.4.2\n",
    )

    with_config(BASIC_CONFIG) do
      assert_equal <<~OUT, kran("version")
        kran     #{Kran::VERSION}
        docker   Docker version 27.0.3, build 7d4bcd8
        krane    krane 3.9.1
        kubectl  Client Version: v1.31.0
      OUT
    end
  end

  test "version reports tools that are missing instead of failing" do
    runner.executables = ["kubectl"]
    runner.captures["kubectl version --client"] = "Client Version: v1.31.0\n"

    with_config(BASIC_CONFIG) do
      assert_equal <<~OUT, kran("version")
        kran     #{Kran::VERSION}
        docker   not found
        krane    not found
        kubectl  Client Version: v1.31.0
      OUT
    end
  end

  test "version reports a tool that fails to run instead of aborting" do
    runner.captures.merge!(
      "docker --version" => "Docker version 27.0.3\n",
      "kubectl version --client" => "Client Version: v1.31.0\n",
    )
    runner.failures["krane version"] = "Command failed (exit 1): krane version\n/x/Gemfile not found (Bundler::GemfileNotFound)"

    with_config(BASIC_CONFIG) do
      output = kran("version")

      assert_includes output, "krane    failed: /x/Gemfile not found (Bundler::GemfileNotFound)\n"
      assert_includes output, "kubectl  Client Version: v1.31.0\n"
    end
  end

  test "version honours krane.command" do
    runner.captures["bundle exec krane version"] = "krane 3.9.1\n"
    runner.executables = ["bundle"]

    with_config(BASIC_CONFIG + "krane:\n  command: bundle exec krane\n") do
      assert_includes kran("version"), "krane    krane 3.9.1\n"
    end
  end

  test "version works without a config file" do
    runner.captures.merge!(
      "docker --version" => "Docker version 27.0.3\n",
      "krane version" => "krane 3.9.1\n",
      "kubectl version --client" => "Client Version: v1.31.0\n",
    )

    with_project do
      assert_includes kran("version"), "kran     #{Kran::VERSION}\n"
    end
  end
end
