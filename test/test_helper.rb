$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))

require "kran"
require "active_support"
require "active_support/test_case"
require "minitest/autorun"
require "tmpdir"
require "fileutils"

ActiveSupport::TestCase.test_order = :random

class FakeRunner
  attr_reader :commands, :stdins
  attr_accessor :dry_run, :captures, :executables, :failures

  def initialize(captures: {}, executables: ["docker", "krane", "kubectl", "ejson", "git"])
    @captures = captures
    @executables = executables
    @failures = {}
    @commands = []
    @stdins = []
    @dry_run = false
  end

  def run(command, stdin: nil)
    commands << command
    stdins << stdin
  end

  def capture(command)
    raise Kran::CommandFailed, failures[command] if failures.key?(command)

    captures.fetch(command) { raise Kran::CommandFailed, "Command failed (exit 1): #{command}" }
  end

  def executable?(name)
    executables.include?(name)
  end
end

class ActiveSupport::TestCase
  setup { Kran.runner = FakeRunner.new }
  teardown { Kran.runner = nil }

  def runner
    Kran.runner
  end

  def with_project(files = {})
    Dir.mktmpdir do |dir|
      files.each do |path, content|
        FileUtils.mkdir_p(File.join(dir, File.dirname(path)))
        File.write(File.join(dir, path), content)
      end
      Dir.chdir(dir) { yield }
    end
  end

  def with_config(yaml, extra_files = {})
    with_project(extra_files.merge("config/kran.yml" => yaml)) { yield }
  end

  BASIC_CONFIG = <<~YAML
    image: my-user/my-app
    registry:
      server: ghcr.io
      username: my-user
      password: s3cret
    builder:
      arch: amd64
    kubernetes:
      kubeconfig: ~/.kube/my-cluster.yml
      context: my-cluster
      namespace: my-app
    app:
      selector: app=my-app
  YAML
end
