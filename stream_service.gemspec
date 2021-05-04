# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'stream_service/version'

Gem::Specification.new do |spec|
  spec.name          = "stream_service"
  spec.version       = StreamService::VERSION
  spec.authors       = ["Justin-Holmes"]
  spec.email         = ["justin.ryan.holmes@icloud.com"]

  spec.summary       = %q{Ruby interface to the Ello Streams service}
  spec.homepage      = "https://github.com/ello/streams"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "activesupport", "~> 5"
  spec.add_dependency "oj", "~> 2"

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-json_matchers"
  spec.add_development_dependency "pry"
end
