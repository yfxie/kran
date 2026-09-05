require "test_helper"

class EjsonTest < ActiveSupport::TestCase
  test "fetch decrypts the file once and digs the dotted path" do
    runner.captures["ejson decrypt config/deploy/secrets.ejson"] =
      '{"kubernetes_secrets":{"registry":{"data":{"password":"pw"}}},"plain":"top"}'
    ejson = Kran::Ejson.new("config/deploy/secrets.ejson")

    assert_equal "pw", ejson.fetch("kubernetes_secrets.registry.data.password")
    assert_equal "top", ejson.fetch("plain")
  end

  test "fetch fails clearly when the path is absent" do
    runner.captures["ejson decrypt config/deploy/secrets.ejson"] = '{"registry":{}}'
    ejson = Kran::Ejson.new("config/deploy/secrets.ejson")

    error = assert_raises(Kran::Error) { ejson.fetch("registry.password") }

    assert_equal "registry.password not found in config/deploy/secrets.ejson", error.message
  end

  test "fetch checks that ejson is installed before decrypting" do
    runner.executables = ["docker"]
    ejson = Kran::Ejson.new("config/deploy/secrets.ejson")

    error = assert_raises(Kran::Error) { ejson.fetch("registry.password") }

    assert_match(/\Aejson is not on PATH\./, error.message)
  end

  test "fetch surfaces decryption failures" do
    ejson = Kran::Ejson.new("config/deploy/secrets.ejson")

    assert_raises(Kran::CommandFailed) { ejson.fetch("registry.password") }
  end
end
