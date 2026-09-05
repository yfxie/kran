module Kran
  module CLI
    class Build < Base
      desc "push", "Build the image and push it to the registry"
      option :version, desc: "Image tag (defaults to the git HEAD sha)"
      def push
        ensure_tools("docker")
        push_image(image_tag)
      end

      desc "details", "Show the Docker daemon and builders that builds run on"
      def details
        ensure_tools("docker")
        runner.run(docker.version)
        runner.run(docker.buildx_ls)
      end
    end
  end
end
