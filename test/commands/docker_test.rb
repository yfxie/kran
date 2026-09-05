require "test_helper"

class DockerCommandsTest < ActiveSupport::TestCase
  test "login targets the registry server with the password on stdin" do
    with_config(BASIC_CONFIG) do
      assert_equal "docker login ghcr.io -u my-user --password-stdin", docker.login
    end
  end

  test "login omits the server for Docker Hub" do
    with_config(BASIC_CONFIG.sub("server: ghcr.io", "server:")) do
      assert_equal "docker login -u my-user --password-stdin", docker.login
    end
  end

  test "build pushes the tagged image for the configured platforms from the context" do
    with_config(BASIC_CONFIG) do
      assert_equal "docker build --platform linux/amd64 --push -t ghcr.io/my-user/my-app:abc123 .", docker.build("abc123")
    end
  end

  test "build joins several archs into one platform flag and uses the context" do
    with_config(BASIC_CONFIG.sub("arch: amd64", "arch: [amd64, arm64]\n  context: ./app dir")) do
      assert_equal "docker build --platform linux/amd64,linux/arm64 --push -t ghcr.io/my-user/my-app:abc123 './app dir'",
        docker.build("abc123")
    end
  end

  test "build skips the platform flag when no arch is configured" do
    with_config(BASIC_CONFIG.sub("  arch: amd64\n", "")) do
      assert_equal "docker build --push -t ghcr.io/my-user/my-app:abc123 .", docker.build("abc123")
    end
  end

  test "every command runs against the remote builder through DOCKER_HOST" do
    with_config(BASIC_CONFIG.sub("arch: amd64", "arch: amd64\n  remote: ssh://build@builder")) do
      assert_equal "DOCKER_HOST=ssh://build@builder docker login ghcr.io -u my-user --password-stdin", docker.login
      assert_equal "DOCKER_HOST=ssh://build@builder docker build --platform linux/amd64 --push " \
        "-t ghcr.io/my-user/my-app:abc123 .", docker.build("abc123")
      assert_equal "DOCKER_HOST=ssh://build@builder docker version", docker.version
      assert_equal "DOCKER_HOST=ssh://build@builder docker buildx ls", docker.buildx_ls
    end
  end

  private

  def docker
    Kran::Commands::Docker.new(Kran::Configuration.load)
  end
end
