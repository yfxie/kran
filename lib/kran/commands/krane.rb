require "shellwords"
require "kran/shell"

module Kran
  module Commands
    class Krane
      def initialize(config)
        @config = config
      end

      def render(tag)
        krane("render", "-f", @config.krane.templates, "--current-sha", tag,
          "--bindings", "image=#{@config.absolute_image}:#{tag}")
      end

      def deploy
        kubernetes = @config.kubernetes
        # krane parses options with Thor, where a repeated -f replaces the earlier one
        # instead of appending to it, so every file has to follow a single -f.
        files = [@config.krane.secrets, "-"].compact
        command = krane("deploy", kubernetes.namespace, kubernetes.context, "-f", *files)
        kubernetes.kubeconfig ? "KUBECONFIG=#{Shell.escape(kubernetes.kubeconfig)} #{command}" : command
      end

      def pipeline(tag)
        "#{render(tag)} | #{deploy}"
      end

      def version
        krane("version")
      end

      def executable
        Shellwords.split(@config.krane.command).find { |word| !word.include?("=") }
      end

      private

      def krane(*args)
        "#{@config.krane.command} #{Shell.join(args)}"
      end
    end
  end
end
