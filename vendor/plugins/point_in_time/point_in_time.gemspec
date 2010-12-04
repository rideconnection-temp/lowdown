# -*- encoding: utf-8 -*-


Gem::Specification.new do |s|
  s.name = %q{point_in_time}
  s.version = "1.0.0"

  s.add_dependency('uuidtools', '>= 2.1.1')
  s.add_dependency('acts_as_guid')

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["David Turner"]
  s.date = %q{2010-09-01}
  s.description = %q{point_in_time versions your ActiveRecord models so as to allos point-in-time queries. It is based on Jordan McKible's version_fu, which is based on Rick Olson's acts_as_versioned, and which is compatible with Rails 3.}
  s.email = %q{}
  s.extra_rdoc_files = [
    "README.rdoc"
  ]
  s.files = [
     "init.rb",
     "MIT-LICENSE",
     "Rakefile",
     "README.rdoc",
     "VERSION",
     "lib/point_in_time.rb",
     "lib/point_in_time/point_in_time.rb",
  ]
  s.homepage = %q{}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Gemified version of the point_in_time plugin.}
  s.test_files = [
     "test/db/database.yml",
     "test/db/schema.rb",
     "test/fixtures/author_versions.yml",
     "test/fixtures/authors.yml",
     "test/fixtures/page_versions.yml",
     "test/fixtures/pages.yml",
     "test/models/author.rb",
     "test/models/page.rb",
     "test/test_helper.rb",
     "test/point_in_time_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end
