require "shellwords"

module Kran
  module CLI
    # Thor hands unknown command names to this class, which lets `aliases` from
    # config/kran.yml expand into real commands without shadowing built-in ones.
    class AliasCommand < Thor::DynamicCommand
      def run(instance, args = [])
        expansion = aliases(args)[name]
        return super unless expansion

        Main.start(Shellwords.split(expansion) + args)
      end

      private

      def aliases(args)
        destination = Thor::Options.new(Main.class_options).parse(args)["destination"]
        Configuration.load(destination: destination).aliases
      end
    end
  end
end
