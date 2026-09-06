require "kran/shell"

module Kran
  module Commands
    class Docker
      def initialize(config)
        @config = config
      end

      def login
        registry = @config.registry
        docker("login", registry.server, "-u", registry.username, "--password-stdin")
      end

      def build(tag)
        builder = @config.builder
        docker("build", *platform(builder.arch), "--push", "-t", "#{@config.absolute_image}:#{tag}", builder.context)
      end

      def version
        docker("version")
      end

      def buildx_ls
        docker("buildx", "ls")
      end

      private

      def docker(*args)
        env = @config.env.merge({ "DOCKER_HOST" => @config.builder.remote }.compact)
        Shell.with_env(env, Shell.join(["docker", *args.compact]))
      end

      def platform(archs)
        return [] if archs.empty?

        ["--platform", archs.map { |arch| "linux/#{arch}" }.join(",")]
      end
    end
  end
end
