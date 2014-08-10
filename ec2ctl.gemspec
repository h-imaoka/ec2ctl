# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ec2ctl/version'

Gem::Specification.new do |spec|
  spec.name          = "ec2ctl"
  spec.version       = Ec2ctl::VERSION
  spec.authors       = ["y13i"]
  spec.email         = ["email@y13i.com"]
  spec.summary       = %q{Yet another handy EC2 tools.}
  spec.description   = %q{Can start/stop instances, add/remove to load balancer, remote command via ssh.}
  spec.homepage      = "https://github.com/y13i/ec2ctl"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "thor"
  spec.add_dependency "aws-sdk"
  spec.add_dependency "net-ssh"
  spec.add_dependency "colorize"
  spec.add_dependency "terminal-table"
  spec.add_dependency "unindent"
  spec.add_dependency "aws_config"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
