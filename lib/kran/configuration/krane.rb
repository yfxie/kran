module Kran
  class Configuration
    class Krane < Section
      DEFAULT_TEMPLATES = "config/deploy"
      SECRETS_FILE = "secrets.ejson"

      def templates
        optional("templates", DEFAULT_TEMPLATES)
      end

      def secrets
        optional("secrets") || default_secrets
      end

      def command
        optional("command", "krane")
      end

      private

      def default_secrets
        path = File.join(templates, SECRETS_FILE)
        path if File.exist?(path)
      end
    end
  end
end
