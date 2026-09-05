require "cli/cli_test_case"

class InitTest < CLITestCase
  test "init writes the template to config/kran.yml" do
    with_project do
      output = kran("init")

      assert_equal "Created config/kran.yml\n", output
      assert_equal File.read(File.expand_path("../../lib/kran/templates/kran.yml", __dir__)), File.read("config/kran.yml")
    end
  end

  test "init leaves an existing config alone" do
    with_config("image: keep\n") do
      output = kran("init")

      assert_equal "config/kran.yml already exists (remove it first to create a new one)\n", output
      assert_equal "image: keep\n", File.read("config/kran.yml")
    end
  end

  test "the template loads and resolves every section" do
    with_project do
      kran("init")
      config = Kran::Configuration.load

      assert_equal "ghcr.io/my-user/my-app", config.absolute_image
      refute_predicate config.registry, :credentials?
      assert_equal ["amd64"], config.builder.arch
      assert_equal "my-cluster", config.kubernetes.context
      assert_equal "my-app", config.kubernetes.namespace
      assert_equal "config/deploy", config.krane.templates
      assert_equal "app=my-app", config.app.selector
      assert_equal({ "shell" => "exec --interactive bash", "console" => "exec --interactive bin/rails console" },
        config.aliases)
    end
  end
end
