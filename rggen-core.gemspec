# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rggen/core/version'

Gem::Specification.new do |spec|
  spec.name = 'rggen-core'
  spec.version = RgGen::Core::VERSION
  spec.authors = ['Taichi Ishitani']
  spec.email = ['taichi730@gmail.com']
  spec.license = 'MIT'
  spec.homepage = 'https://github.com/rggen/rggen-core'

  spec.summary = 'Core components for RgGen tool'
  spec.description = <<-EOS
    RgGen is a code generator tool for SoC/IP/FPGA/RTL engineers.
    It will automatically generate source code for control/status registers, e.g. RTL, UVM RAL model, C header file, from its register map document.
    Also RgGen is customizable so you can build your specific generate tool.
  EOS

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir = 'exe'
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.3'

  spec.add_runtime_dependency 'docile', '>= 1.1.5'
  spec.add_runtime_dependency 'erubi', '>= 1.7'
  spec.add_runtime_dependency 'facets', '>= 3.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
end
