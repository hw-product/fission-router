$LOAD_PATH.unshift File.expand_path(File.dirname(__FILE__)) + '/lib/'
require 'fission-router/version'
Gem::Specification.new do |s|
  s.name = 'fission-router'
  s.version = Fission::Router::VERSION.version
  s.summary = 'Fission Router'
  s.author = 'Heavywater'
  s.email = 'fission@hw-ops.com'
  s.homepage = 'http://github.com/heavywater/fission-router'
  s.description = 'Fission Router'
  s.require_path = 'lib'
  s.add_dependency 'fission', '>= 0.2.4', '< 1.0.0'
  s.files = Dir['{lib}/**/**/*'] + %w(fission-router.gemspec README.md CHANGELOG.md)
end
