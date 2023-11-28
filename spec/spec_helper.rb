# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  enable_coverage :branch
end

require 'bundler/setup'
require 'proformaxml'
require 'rspec/collection_matchers'
require 'factory_bot'
require 'pry-byebug'

Dir['./spec/support/**/*.rb'].each {|f| require f }
# RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 999_999_999

RSpec::Matchers.define_negated_matcher :not_include, :include

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.include FactoryBot::Syntax::Methods

  config.before(:suite) do
    FactoryBot.find_definitions
  end

  config.add_setting :file_fixture_path, default: 'spec/fixtures/files'
end
