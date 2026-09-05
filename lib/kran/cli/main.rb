require "fileutils"

module Kran
  module CLI
    class Main < Base
      TEMPLATE = File.expand_path("../templates/kran.yml", __dir__)

      class << self
        def dynamic_command_class
          AliasCommand
        end
      end

      desc "init", "Create config/kran.yml"
      def init
        if File.exist?(Configuration::FILE)
          say "#{Configuration::FILE} already exists (remove it first to create a new one)"
        else
          FileUtils.mkdir_p(File.dirname(Configuration::FILE))
          FileUtils.cp(TEMPLATE, Configuration::FILE)
          say "Created #{Configuration::FILE}"
        end
      end

      desc "deploy", "Build and push the image, then render and deploy with krane"
      option :version, desc: "Image tag (defaults to the git HEAD sha)"
      option :skip_push, aliases: "-P", type: :boolean, default: false, desc: "Skip the image build and push"
      def deploy
        tools = options[:skip_push] ? [] : ["docker"]
        ensure_tools(*tools, krane.executable, "kubectl")
        tag = image_tag
        push_image(tag) unless options[:skip_push]
        runner.run(krane.pipeline(tag))
      end

      desc "build SUBCOMMAND", "Build the image (push, details)"
      subcommand "build", Build

      desc "logs", "Show logs from the app pods"
      option :follow, aliases: "-f", type: :boolean, default: false, desc: "Stream new lines as they arrive"
      option :lines, aliases: "-n", type: :numeric, desc: "Number of recent lines per pod"
      option :since, aliases: "-s", desc: "Only lines newer than this, for example 10m or 1h"
      option :grep, aliases: "-g", desc: "Only lines matching this pattern"
      def logs
        ensure_tools("kubectl")
        runner.run(kubectl.logs(**options.slice("follow", "lines", "since", "grep").symbolize_keys))
      end

      desc "exec COMMAND...", "Run a command in a running app pod"
      option :interactive, aliases: "-i", type: :boolean, default: false, desc: "Attach a terminal"
      def exec(*command)
        if command.empty?
          raise Error, "exec needs a command to run, for example `kran exec bin/rails db:migrate`"
        end

        ensure_tools("kubectl")
        runner.run(kubectl.exec(command, interactive: options[:interactive]))
      end

      desc "details", "Show every resource in the namespace"
      def details
        ensure_tools("kubectl")
        runner.run(kubectl.details)
      end

      desc "audit", "Show the rollout history of the app deployments"
      def audit
        ensure_tools("kubectl")
        runner.run(kubectl.audit)
      end

      desc "version", "Show the versions of kran, docker, krane and kubectl"
      def version
        krane_commands = Commands::Krane.new(File.exist?(Configuration::FILE) ? config : Configuration.new({}))
        say "kran     #{VERSION}"
        say "docker   #{tool_version("docker", "docker --version")}"
        say "krane    #{tool_version(krane_commands.executable, krane_commands.version)}"
        say "kubectl  #{tool_version("kubectl", "kubectl version --client")}"
      end

      private

      def tool_version(executable, command)
        return "not found" unless Kran.runner.executable?(executable)

        Kran.runner.capture(command).lines.first.to_s.strip
      rescue CommandFailed => error
        "failed: #{error.message.lines[1].to_s.strip}"
      end
    end
  end
end
