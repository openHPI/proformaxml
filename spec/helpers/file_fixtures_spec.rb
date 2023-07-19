# frozen_string_literal: true

require 'rspec'

RSpec.describe 'FileFixtures' do
  subject(:fixture) { file_fixture(filename) }

  context 'when supplying a valid filename' do
    let(:filename) { 'task_with_valid_test_config.xml' }

    it 'finds a file with a size' do
      expect(fixture.size).to be > 0
    end
  end

  context 'when supplying an invalid filename' do
    let(:filename) { 'invalid' }

    it 'finds a file with a size' do
      expect { fixture }.to raise_error ArgumentError, "the directory 'spec/fixtures/files' does not contain a file named 'invalid'"
    end
  end
end
