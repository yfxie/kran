require "erb"
require "yaml"
require "active_support/core_ext/hash/deep_merge"
require "kran/configuration/section"
require "kran/configuration/registry"
require "kran/configuration/builder"
require "kran/configuration/kubernetes"
require "kran/configuration/krane"
require "kran/configuration/app"

module Kran
  class Configuration
    FILE = "config/kran.yml"

    class << self
      def load(destination: nil)
        raw = load_file(FILE, destination, hint: " (run `kran init` to create one)")
        raw = raw.deep_merge(load_file(destination_file(destination), destination)) if destination
        new(raw, destination: destination)
      end

      private

      def destination_file(destination)
        FILE.sub(/\.yml\z/, ".#{destination}.yml")
      end

      def load_file(file, destination, hint: "")
        raise Error, "Configuration file not found in #{file}#{hint}" unless File.exist?(file)

        rendered = ERB.new(File.read(file), trim_mode: "-").result_with_hash(destination: destination)
        YAML.safe_load(rendered, aliases: true) || {}
      end
    end

    attr_reader :destination

    def initialize(raw, destination: nil)
      @raw = raw
      @destination = destination
    end

    def image
      @raw.fetch("image") { raise Error, "Missing image in #{FILE}" }
    end

    def absolute_image
      [registry.server, image].compact.join("/")
    end

    def registry
      @registry ||= Registry.new(@raw, ejson: krane.secrets && Ejson.new(krane.secrets))
    end

    def builder
      @builder ||= Builder.new(@raw)
    end

    def kubernetes
      @kubernetes ||= Kubernetes.new(@raw)
    end

    def krane
      @krane ||= Krane.new(@raw)
    end

    def app
      @app ||= App.new(@raw)
    end

    def aliases
      @raw.fetch("aliases", {})
    end

    def env
      @raw.fetch("env", {}).transform_values(&:to_s)
    end
  end
end
