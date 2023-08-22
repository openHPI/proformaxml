# frozen_string_literal: true

RSpec.describe ProformaXML::Validator do
  describe '.new' do
    subject(:validator) { described_class.new(doc) }

    let(:zip_file) { ProformaXML::Exporter.new(task: build(:task)).perform }
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
      expect(validator.instance_variable_get(:@doc)).to be_a Nokogiri::XML::Document
    end

    it 'does not assign expected_version' do
      expect(validator.instance_variable_get(:@expected_version)).to be_nil
    end

    context 'with a specific expected_version' do
      subject(:validator) { described_class.new(zip_file, expected_version) }

      let(:expected_version) { '2.0' }

      it 'does not assign expected_version' do
        expect(validator.instance_variable_get(:@expected_version)).to eql '2.0'
      end
    end
  end

  describe '#perform' do
    subject(:perform) { validator.perform }

    let(:zip_file) { ProformaXML::Exporter.new(task:, version: export_version).perform }
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
    let(:validator) { described_class.new(doc) }
    let(:task) { build(:task) }
    let(:export_version) {}

    it { is_expected.to be_empty }

    context 'when input is not a proformaxml xml' do
      let(:doc) do
        Nokogiri::XML('<root><aliens><alien><name>Alf</name></alien></aliens></root>')
      end

      it { is_expected.to include 'no proformaxml version found' }
    end

    context 'with expected_version' do
      let(:validator) { described_class.new(doc, expected_version) }
      let(:expected_version) { '2.0' }

      context 'when export_version is the same' do
        let(:export_version) { expected_version }

        it { is_expected.to be_empty }
      end

      context 'when export_version is different' do
        let(:export_version) { '2.1' }

        it { is_expected.to include Nokogiri::XML::SyntaxError }
      end
    end

    context 'when task contains validatable test-configuration' do
      shared_examples 'validates successfully' do |test_type|
        let(:task) { build(:task, tests: build_list(:test, 1, test_type)) }

        it { is_expected.to be_empty }
      end

      it_behaves_like 'validates successfully', :with_unittest
      it_behaves_like 'validates successfully', :with_java_checkstyle
      it_behaves_like 'validates successfully', :with_regexptest

      context 'with all test-types' do
        let(:xml_file) { file_fixture("#{filename}.xml") }
        let(:doc) { Nokogiri::XML xml_file.read }

        context 'without errors' do
          let(:filename) { 'task_with_valid_test_config' }

          it { is_expected.to be_empty }
        end

        context 'with a lot of errors' do
          let(:filename) { 'task_with_invalid_test_config' }

          it 'returns the correct errors' do
            expect(validator.perform).to contain_exactly(
              an_object_having_attributes(message: a_string_including("Element '{urn:proforma:tests:unittest:v1.1}entry-ploint': This element is not expected.")),
              an_object_having_attributes(message: a_string_including("Element '{urn:proforma:tests:java-checkstyle:v1.1}max-checkstyle-wlarnings': This element is not expected.")),
              an_object_having_attributes(message: a_string_including("Element '{urn:proforma:tests:regexptest:v0.9}regular-espresso': This element is not expected."))
            )
          end
        end
      end
    end
  end
end
