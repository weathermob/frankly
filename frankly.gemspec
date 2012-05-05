# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "frankly"
  s.version     = "0.0.1"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Ben Griffiths"]
  s.email       = ["bengriffiths@gmail.com"]
  s.homepage    = "http://github.com/weathermob/frankly"
  s.summary     = %q{Frank API client}
  s.description = %q{Wrapper for frank api}

  s.add_dependency( "sim_launcher" )
  s.add_dependency( "i18n" )

  s.add_development_dependency "rake"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
