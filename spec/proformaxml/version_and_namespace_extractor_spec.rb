# frozen_string_literal: true

RSpec.describe ProformaXML::VersionAndNamespaceExtractor do
  describe '.new' do
    subject(:extractor) { described_class.new(doc:) }

    let(:zip_file) { ProformaXML::Exporter.call(task: build(:task)) }
    let(:zip_content) do
      {}.tap do |hash|
        Zip::InputStream.open(zip_file) do |io|
          while (entry = io.get_next_entry)
            hash[entry.name] = entry.get_input_stream.read
          end
        end
      end
    end
    let(:doc) { Nokogiri::XML(zip_content['task.xml'], &:noblanks) }

    it 'assigns doc' do
      expect(extractor.instance_variable_get(:@doc)).to be_a Nokogiri::XML::Document
    end
  end

  describe '#perform' do
    subject(:perform) { described_class.call(doc:) }

    let(:zip_file) { ProformaXML::Exporter.call(task:, version: export_version) }
    let(:zip_content) do
      {}.tap do |hash|
        Zip::InputStream.open(zip_file) do |io|
          while (entry = io.get_next_entry)
            hash[entry.name] = entry.get_input_stream.read
          end
        end
      end
    end
    let(:doc) { Nokogiri::XML(zip_content['task.xml'], &:noblanks) }
    let(:task) { build(:task) }
    let(:export_version) {}

    context 'when export_version is 2.1' do
      let(:export_version) { '2.1' }

      it { is_expected.to include(version: '2.1') }
    end

    context 'when export_version is 2.0' do
      let(:export_version) { '2.0' }

      it { is_expected.to include(version: '2.0') }
    end

    it { is_expected.to include(namespace: 'xmlns') }

    context 'with prefixed ProFormA namespace' do
      let(:xml_file) { file_fixture('task_with_prefixed_proforma_namespace.xml') }
      let(:doc) { Nokogiri::XML xml_file.read }

      it { is_expected.to include(namespace: 'p') }
    end
  end
end
