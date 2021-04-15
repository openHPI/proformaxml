# frozen_string_literal: true

RSpec.shared_examples 'mass assignable' do |attributes|
  let(:params) { attributes.map { |i| [i, i] }.to_h }

  it 'supports mass-assignments' do
    expect(described_class.new(params)).to have_attributes(params)
  end
end

RSpec.shared_examples 'collections mass assignable' do |collection_attributes|
  let(:collection_attribute_dummy) { [1, 2, 'a', 'b'] }
  collection_attributes.each do |collection_attribute|
    it 'sets default value for collection_attribute' do
      expect(
        described_class.new(
          collection_attribute => collection_attribute_dummy
        )
      ).to have_attributes(collection_attribute => collection_attribute_dummy)
    end
  end

  context 'when collection_attributes are not supplied' do
    collection_attributes.each do |collection_attribute|
      it 'sets default value for collection_attribute' do
        expect(described_class.new).to have_attributes(collection_attribute => [])
      end
    end
  end
end
