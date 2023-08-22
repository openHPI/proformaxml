# frozen_string_literal: true

require_relative 'lib/proformaxml/version'

Gem::Specification.new do |spec|
  spec.name          = 'proformaxml'
  spec.version       = ProformaXML::VERSION
  spec.authors       = ['Karol']
  spec.email         = ['git@koehn.pro']

  spec.summary       = 'Implements parts of ProFormA-XML specification'
  spec.description   = 'Offers datastructure and (de)serializer according to ProFormA-XML specification.'
  spec.homepage      = 'https://github.com/openHPI/proformaxml'
  spec.license       = 'MIT'

  spec.required_ruby_version = '>= 3.2'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (f == __FILE__) || f.match(%r{\A(?:(?:bin|test|spec|features)/|\.(?:git|circleci)|appveyor)})
    end
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) {|f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activemodel', '>= 5.2.3', '< 8.0.0'
  spec.add_dependency 'activesupport', '>= 5.2.3', '< 8.0.0'
  spec.add_dependency 'dachsfisch', '>= 0.1.0', '< 1.0.0'
  spec.add_dependency 'nokogiri', '>= 1.10.2', '< 2.0.0'
  spec.add_dependency 'rubyzip', '>= 1.2.2', '< 3.0.0'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
