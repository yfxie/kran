require "kran/shell"

module Kran
  module Commands
    class Kubectl
      def initialize(config)
        @config = config
      end

      def logs(lines: nil, since: nil, follow: false, grep: nil)
        command = kubectl("logs", "-l", selector, *container, "--prefix", "--timestamps",
          *(["--tail", lines.to_s] if lines), *(["--since", since] if since), *("-f" if follow))
        grep ? "#{command} | grep #{Shell.escape(grep)}" : command
      end

      def exec(command, interactive: false)
        <<~SH.chomp
          pod=$(#{running_pod}) && test -n "$pod" || { echo #{Shell.escape("No running pod matches #{selector}")} >&2; exit 1; }
          #{kubectl("exec", *("-it" if interactive))} "$pod" #{Shell.join([*container, "--", *command])}
        SH
      end

      def details
        kubectl("get", "all", "-o", "wide")
      end

      def audit
        kubectl("rollout", "history", "deployment", "-l", selector)
      end

      private

      def running_pod
        kubectl("get", "pods", "-l", selector, "--field-selector", "status.phase=Running",
          "-o", "jsonpath={.items[0].metadata.name}")
      end

      def selector
        @config.app.selector
      end

      def container
        name = @config.app.container
        name ? ["-c", name] : []
      end

      def kubectl(*args)
        kubernetes = @config.kubernetes
        env = @config.env.merge({ "KUBECONFIG" => kubernetes.kubeconfig }.compact)
        Shell.with_env(env, Shell.join(["kubectl", "--context", kubernetes.context, "--namespace", kubernetes.namespace, *args.compact]))
      end
    end
  end
end
