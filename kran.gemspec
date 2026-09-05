require_relative "lib/kran/version"

Gem::Specification.new do |spec|
  spec.name = "kran"
  spec.version = Kran::VERSION
  spec.authors = ["Yi Feng Xie"]
  spec.email = ["yfxie@me.com"]
  spec.summary = "Deploy to Kubernetes with krane, the simple way"
  spec.description = "One command to build, push, render and deploy with krane, " \
    "plus helpers for logs, exec, details and audit."
  spec.homepage = "https://kran.bincode.tw"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"
  spec.metadata = {
    "homepage_uri" => "https://kran.bincode.tw",
    "source_code_uri" => "https://github.com/yfxie/kran",
    "bug_tracker_uri" => "https://github.com/yfxie/kran/issues",
  }

  spec.files = Dir["lib/**/*", "exe/*", "README.md", "LICENSE"]
  spec.bindir = "exe"
  spec.executables = ["kran"]

  spec.add_dependency("activesupport", ">= 7.1")
  spec.add_dependency("thor", "~> 1.3")
end
