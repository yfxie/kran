require "thor"

module Kran
  module CLI
    class Base < Thor
      class_option :destination, aliases: "-d", desc: "Layer config/kran.<destination>.yml over config/kran.yml"
      # No default here: Thor merges a subcommand's options over the parent's,
      # so a default of false would erase `--dry-run` given before `build push`.
      class_option :dry_run, type: :boolean, desc: "Print the commands instead of running them"

      class << self
        def exit_on_failure?
          true
        end

        def basename
          "kran"
        end
      end

      private

      def config
        @config ||= Configuration.load(destination: options[:destination])
      end

      def runner
        Kran.runner.tap { |runner| runner.dry_run = options[:dry_run] }
      end

      def docker
        Commands::Docker.new(config)
      end

      def krane
        Commands::Krane.new(config)
      end

      def kubectl
        Commands::Kubectl.new(config)
      end

      def image_tag
        options[:version] || Git.new.version
      end

      def ensure_tools(*names)
        Dependencies.new.ensure!(*names) unless options[:dry_run]
      end

      def push_image(tag)
        runner.run(docker.login, stdin: config.registry.password) if config.registry.credentials?
        runner.run(docker.build(tag))
      end
    end
  end
end
