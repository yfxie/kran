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
        command = Shell.join(["docker", *args.compact])
        remote = @config.builder.remote
        remote ? "DOCKER_HOST=#{Shell.escape(remote)} #{command}" : command
      end

      def platform(archs)
        return [] if archs.empty?

        ["--platform", archs.map { |arch| "linux/#{arch}" }.join(",")]
      end
    end
  end
end
