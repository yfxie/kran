require "test_helper"

class CLITestCase < ActiveSupport::TestCase
  SHA = "3f2a9c0d8e7b6a5f4e3d2c1b0a9f8e7d6c5b4a39"
  KUBECTL = "KUBECONFIG=#{File.expand_path("~/.kube/my-cluster.yml")} kubectl --context my-cluster --namespace my-app"

  setup do
    runner.captures.merge!("git rev-parse HEAD" => "#{SHA}\n", "git status --porcelain" => "")
  end

  private

  def kran(*args)
    stdout, = capture_io { Kran::CLI::Main.start(args) }
    stdout
  end

  def kran_error(*args)
    assert_raises(Kran::Error) { capture_io { Kran::CLI::Main.start(args) } }
  end
end
