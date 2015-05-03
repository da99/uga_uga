# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "uga_uga"
  spec.version       = `cat VERSION`
  spec.authors       = ["da99"]
  spec.email         = ["i-hate-spam-1234567@mailinator.com"]
  spec.summary       = %q{A little tool to help you write DSLs.}
  spec.description   = %q{
    It takes in a String and gives you back a
    stupid data structure of commands, blocks, and Strings.
    You then do stuff to make that stuff come alive.
    Whatever... I don't have time to tell you exactly
    since you will use Treetop anyway:
    https://github.com/nathansobo/treetop
  }
  spec.homepage      = "https://github.com/da99/uga_uga"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |file|
    file.index('bin/') == 0 && file != "bin/#{File.basename Dir.pwd}"
  }
  spec.executables   = spec.files.grep("bin/#{spec.name}") { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.2.0'

  spec.add_dependency "rex_dots"           , "> 0.0.1"

  spec.add_development_dependency "pry"           , "> 0.9"
  spec.add_development_dependency "bundler"       , "> 1.5"
  spec.add_development_dependency "bacon"         , "> 1.0"
  spec.add_development_dependency "Bacon_Colored" , "> 0.1"
  spec.add_development_dependency "awesome_print" , "> 0.1"
end
