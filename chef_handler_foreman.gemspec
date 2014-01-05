# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chef_handler_foreman/version'

Gem::Specification.new do |spec|
  spec.name          = "chef_handler_foreman"
  spec.version       = ChefHandlerForeman::VERSION
  spec.authors       = ["Marek Hulan"]
  spec.email         = ["mhulan@redhat.com"]
  spec.description   = %q{Chef handlers to integrate with foreman}
  spec.summary       = %q{This gem adds chef handlers so your chef-client can upload attributes (facts) and reports to Foreman}
  spec.homepage      = "https://github.com/theforeman/chef-handler-foreman"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
