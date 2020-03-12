lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'cleanup_vendor/version'

Gem::Specification.new do |spec|
  spec.name          = 'cleanup_vendor'
  spec.version       = CleanupVendor::VERSION
  spec.authors       = ['KARASZI István']
  spec.email         = ['github@spam.raszi.hu']

  spec.summary       = 'This gem helps to cleanup vendor directory'
  spec.description   = 'Removes unnecessary files which are not required in production environment.'
  spec.homepage      = 'https://github.com/raszi/cleanup_vendor'
  spec.license       = 'MIT'

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.17'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'pry-byebug', '~> 3.8'
  spec.add_development_dependency 'pry-doc', '~> 1.0'
  spec.add_development_dependency 'simplecov', '~> 0.18.5'
end
