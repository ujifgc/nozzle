# coding: utf-8
require File.expand_path('../lib/nozzle/version', __FILE__)

Gem::Specification.new do |spec|
  spec.name          = 'nozzle'
  spec.version       = Nozzle::VERSION
  spec.description   = 'Attachments for ruby rack'
  spec.summary       = 'A gem to store and serve attachments for ruby rack applications'

  spec.authors       = ['Igor Bochkariov']
  spec.email         = ['ujifgc@gmail.com']
  spec.homepage      = 'https://github.com/ujifgc/nozzle'
  spec.license       = 'MIT'

  spec.require_paths = ['lib']
  spec.files         = `git ls-files`.split($/)
  spec.test_files    = spec.files.grep(%r{^test/})

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
end
