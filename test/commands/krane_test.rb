require "test_helper"

class KraneCommandsTest < ActiveSupport::TestCase
  test "render passes the templates, the tag as current-sha and the image binding" do
    with_config(BASIC_CONFIG) do
      assert_equal "krane render -f config/deploy --current-sha abc123 --bindings image=ghcr.io/my-user/my-app:abc123",
        krane.render("abc123")
    end
  end

  test "deploy targets the namespace and context with kubeconfig, secrets and stdin templates" do
    with_config(BASIC_CONFIG, "config/deploy/secrets.ejson" => "{}") do
      assert_equal "KUBECONFIG=#{File.expand_path("~/.kube/my-cluster.yml")} krane deploy my-app my-cluster " \
        "-f config/deploy/secrets.ejson -", krane.deploy
    end
  end

  test "deploy leaves out kubeconfig and secrets when they are not configured" do
    with_config(BASIC_CONFIG.sub("  kubeconfig: ~/.kube/my-cluster.yml\n", "")) do
      assert_equal "krane deploy my-app my-cluster -f -", krane.deploy
    end
  end

  test "pipeline pipes render into deploy" do
    with_config(BASIC_CONFIG.sub("  kubeconfig: ~/.kube/my-cluster.yml\n", "")) do
      assert_equal "#{krane.render("abc123")} | #{krane.deploy}", krane.pipeline("abc123")
    end
  end

  test "commands honour krane.command and templates" do
    yaml = BASIC_CONFIG + "krane:\n  command: BUNDLE_GEMFILE=deploy/Gemfile bundle exec krane\n  templates: k8s\n"
    with_config(yaml) do
      assert_equal "BUNDLE_GEMFILE=deploy/Gemfile bundle exec krane render -f k8s --current-sha abc123 " \
        "--bindings image=ghcr.io/my-user/my-app:abc123", krane.render("abc123")
      assert_equal "BUNDLE_GEMFILE=deploy/Gemfile bundle exec krane version", krane.version
      assert_equal "bundle", krane.executable
    end
  end

  private

  def krane
    Kran::Commands::Krane.new(Kran::Configuration.load)
  end
end
