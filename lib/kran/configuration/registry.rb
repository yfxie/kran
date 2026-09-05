module Kran
  class Configuration
    class Registry < Section
      def initialize(raw, ejson: nil)
        super(raw)
        @ejson = ejson
      end

      def server
        value = optional("server")
        value.to_s.empty? ? nil : value
      end

      def credentials?
        return false if optional("username").nil? && optional("password").nil?
        return true if optional("username") && optional("password")

        raise Error, "Set registry.username and registry.password together in #{Configuration::FILE}, " \
          "or leave both out to reuse the login docker already has"
      end

      def username
        resolve("username")
      end

      def password
        resolve("password")
      end

      private

      def resolve(key)
        case optional(key)
        in Hash => reference then fetch_from_ejson(key, reference.fetch("ejson"))
        in value then value
        end
      end

      def fetch_from_ejson(key, path)
        if @ejson.nil?
          raise Error, "registry.#{key} refers to ejson but krane.secrets is not set and " \
            "#{Krane::DEFAULT_TEMPLATES}/#{Krane::SECRETS_FILE} does not exist"
        end

        @ejson.fetch(path)
      end
    end
  end
end
