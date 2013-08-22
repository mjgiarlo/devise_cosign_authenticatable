lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'devise_cosign_authenticatable/version'

Gem::Specification.new do |s|
  s.name          = 'devise_cosign_authenticatable'
  s.version       = DeviseCosignAuthenticatable::VERSION
  s.authors       = ['Michael J. Giarlo']
  s.email         = ['leftwing@alumni.rutgers.edu']
  s.summary       = 'CoSign authentication module for Devise'
  s.description   = s.summary
  s.homepage      = 'https://github.com/mjgiarlo/devise_cosign_authenticatable'
  s.license       = 'APACHE2'

  s.files         = `git ls-files`.split($/)
  s.executables   = s.files.grep(%r{^bin/}) { |f| File.basename(f) }
  s.test_files    = s.files.grep(%r{(test|spec|features)/})
  s.require_paths = ['lib']

  s.add_dependency 'devise', '>= 2.2.0'
  s.add_dependency 'rubycas-client', '>= 2.2.1'

  s.add_development_dependency 'rails', '>= 3.2.13', '< 5.0'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'sqlite3-ruby'
  s.add_development_dependency 'sham_rack'
  s.add_development_dependency 'capybara', '~> 1.1.4'
  s.add_development_dependency 'crypt-isaac'
  s.add_development_dependency 'launchy'
  s.add_development_dependency 'timecop'
end

