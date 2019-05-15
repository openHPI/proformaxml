# frozen_string_literal: true

RSpec.shared_examples 'mass assignable' do |attributes|
  let(:params) { Hash[attributes.map { |i| [i, i] }] }

  it 'supports mass-assignments' do
    expect(described_class.new(params)).to have_attributes(params)
  end
end
