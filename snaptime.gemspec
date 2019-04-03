# -*- encoding: utf-8 -*-
# stub: snaptime 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "snaptime".freeze
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Sitrox".freeze]
  s.date = "2019-04-03"
  s.files = [".gitignore".freeze, ".releaser_config".freeze, "Gemfile".freeze, "Gemfile.lock".freeze, "LICENSE".freeze, "README.md".freeze, "Rakefile".freeze, "VERSION".freeze, "lib/snaptime.rb".freeze, "lib/snaptime/ar_hooks.rb".freeze, "lib/snaptime/base_ar_mixin.rb".freeze, "lib/snaptime/exceptions.rb".freeze, "lib/snaptime/harvester.rb".freeze, "lib/snaptime/migration_helpers.rb".freeze, "lib/snaptime/railtie.rb".freeze, "lib/snaptime/record_cloner.rb".freeze, "lib/snaptime/relations.rb".freeze, "lib/snaptime/relations_builder.rb".freeze, "lib/snaptime/versioned.rb".freeze, "lib/snaptime/versioned/scopes.rb".freeze, "lib/snaptime/virtual_models/snaptime.rb".freeze, "snaptime.gemspec".freeze]
  s.rubygems_version = "2.5.2.3".freeze
  s.summary = "Multi-threaded job backend with database queuing for ruby.".freeze

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rubocop>.freeze, ["= 0.51.0"])
      s.add_development_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_development_dependency(%q<mysql2>.freeze, [">= 0"])
      s.add_development_dependency(%q<benchmark-ips>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<activerecord>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<request_store>.freeze, [">= 0"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 2.0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rubocop>.freeze, ["= 0.51.0"])
      s.add_dependency(%q<minitest>.freeze, [">= 0"])
      s.add_dependency(%q<mysql2>.freeze, [">= 0"])
      s.add_dependency(%q<benchmark-ips>.freeze, [">= 0"])
      s.add_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_dependency(%q<activerecord>.freeze, [">= 0"])
      s.add_dependency(%q<request_store>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rubocop>.freeze, ["= 0.51.0"])
    s.add_dependency(%q<minitest>.freeze, [">= 0"])
    s.add_dependency(%q<mysql2>.freeze, [">= 0"])
    s.add_dependency(%q<benchmark-ips>.freeze, [">= 0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<activerecord>.freeze, [">= 0"])
    s.add_dependency(%q<request_store>.freeze, [">= 0"])
  end
end