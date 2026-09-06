require "test_helper"

class ConfigurationTest < ActiveSupport::TestCase
  test "reads every section from config/kran.yml" do
    with_config(BASIC_CONFIG) do
      config = Kran::Configuration.load

      assert_equal "my-user/my-app", config.image
      assert_equal "ghcr.io", config.registry.server
      assert_equal "my-user", config.registry.username
      assert_equal "s3cret", config.registry.password
      assert_equal ["amd64"], config.builder.arch
      assert_equal File.expand_path("~/.kube/my-cluster.yml"), config.kubernetes.kubeconfig
      assert_equal "my-cluster", config.kubernetes.context
      assert_equal "my-app", config.kubernetes.namespace
      assert_equal "app=my-app", config.app.selector
    end
  end

  test "fills in defaults for optional keys" do
    with_config(BASIC_CONFIG) do
      config = Kran::Configuration.load

      assert_nil config.builder.remote
      assert_equal ".", config.builder.context
      assert_equal "config/deploy", config.krane.templates
      assert_nil config.krane.secrets
      assert_equal "krane", config.krane.command
      assert_nil config.app.container
      assert_empty config.aliases
      assert_empty config.env
    end
  end

  test "env values are strings and destination files add to them" do
    base = BASIC_CONFIG + "env:\n  CLOUDSDK_ACTIVE_CONFIG_NAME: acme\n  BUILDKIT_PROGRESS: plain\n"
    staging = "env:\n  CLOUDSDK_ACTIVE_CONFIG_NAME: acme-staging\n  DOCKER_BUILDKIT: 1\n"
    with_config(base, "config/kran.staging.yml" => staging) do
      assert_equal({ "CLOUDSDK_ACTIVE_CONFIG_NAME" => "acme-staging", "BUILDKIT_PROGRESS" => "plain",
                     "DOCKER_BUILDKIT" => "1" }, Kran::Configuration.load(destination: "staging").env)
    end
  end

  test "krane.secrets defaults to secrets.ejson inside the templates directory when it exists" do
    with_config(BASIC_CONFIG, "config/deploy/secrets.ejson" => "{}") do
      assert_equal "config/deploy/secrets.ejson", Kran::Configuration.load.krane.secrets
    end
  end

  test "absolute_image prefixes the registry server and omits it for Docker Hub" do
    with_config(BASIC_CONFIG) do
      assert_equal "ghcr.io/my-user/my-app", Kran::Configuration.load.absolute_image
    end

    with_config(BASIC_CONFIG.sub("server: ghcr.io", "server:")) do
      assert_equal "my-user/my-app", Kran::Configuration.load.absolute_image
    end
  end

  test "evaluates ERB with the destination available" do
    with_config("image: my-user/my-app\nkubernetes:\n  context: <%= destination %>-cluster\n  namespace: x\n") do
      assert_equal "-cluster", Kran::Configuration.load.kubernetes.context
    end
  end

  test "deep merges the destination file over the base file" do
    staging = "kubernetes:\n  namespace: my-app-staging\nbuilder:\n  arch: [amd64, arm64]\n"
    with_config(BASIC_CONFIG, "config/kran.staging.yml" => staging) do
      config = Kran::Configuration.load(destination: "staging")

      assert_equal "staging", config.destination
      assert_equal "my-app-staging", config.kubernetes.namespace
      assert_equal "my-cluster", config.kubernetes.context
      assert_equal ["amd64", "arm64"], config.builder.arch
    end
  end

  test "fails clearly when the destination file is missing" do
    with_config(BASIC_CONFIG) do
      error = assert_raises(Kran::Error) { Kran::Configuration.load(destination: "staging") }

      assert_equal "Configuration file not found in config/kran.staging.yml", error.message
    end
  end

  test "fails clearly when the config file is missing" do
    with_project do
      error = assert_raises(Kran::Error) { Kran::Configuration.load }

      assert_equal "Configuration file not found in config/kran.yml (run `kran init` to create one)", error.message
    end
  end

  test "fails clearly when a required key is missing" do
    with_config("image: my-user/my-app\nkubernetes:\n  namespace: x\n") do
      error = assert_raises(Kran::Error) { Kran::Configuration.load.kubernetes.context }

      assert_equal "Missing kubernetes.context in config/kran.yml", error.message
    end
  end

  test "reads registry credentials from secrets.ejson" do
    runner.captures["ejson decrypt config/deploy/secrets.ejson"] = '{"registry":{"password":"from-ejson"}}'
    yaml = BASIC_CONFIG.sub("password: s3cret", "password:\n    ejson: registry.password")

    with_config(yaml, "config/deploy/secrets.ejson" => "{}") do
      assert_equal "from-ejson", Kran::Configuration.load.registry.password
    end
  end

  test "fails clearly when an ejson reference is used without a secrets file" do
    yaml = BASIC_CONFIG.sub("password: s3cret", "password:\n    ejson: registry.password")

    with_config(yaml) do
      error = assert_raises(Kran::Error) { Kran::Configuration.load.registry.password }

      assert_equal "registry.password refers to ejson but krane.secrets is not set and " \
        "config/deploy/secrets.ejson does not exist", error.message
    end
  end

  test "registry credentials are optional" do
    with_config(BASIC_CONFIG.sub("  username: my-user\n  password: s3cret\n", "")) do
      registry = Kran::Configuration.load.registry

      refute_predicate registry, :credentials?
      assert_nil registry.username
      assert_nil registry.password
    end
  end

  test "fails clearly when only one of registry.username and registry.password is set" do
    with_config(BASIC_CONFIG.sub("  password: s3cret\n", "")) do
      error = assert_raises(Kran::Error) { Kran::Configuration.load.registry.credentials? }

      assert_equal "Set registry.username and registry.password together in config/kran.yml, " \
        "or leave both out to reuse the login docker already has", error.message
    end
  end
end
