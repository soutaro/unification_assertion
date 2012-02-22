# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "unification_assertion/version"

Gem::Specification.new do |s|
  s.name        = "unification_assertion"
  s.version     = UnificationAssertion::VERSION
  s.authors     = ["Soutaro Matsumoto"]
  s.email       = ["matsumoto@soutaro.com"]
  s.homepage    = "https://github.com/soutaro/unification_assertion"
  s.summary     = "Assertion to test unifiability of two structures"
  s.description = "UnificationAssertion defines +assert_unifiable+ assertion to test if given two values are unifiable."

  s.rubyforge_project = "unification_assertion"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
end
