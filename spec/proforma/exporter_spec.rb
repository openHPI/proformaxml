# frozen_string_literal: true

RSpec.describe Proforma::Exporter do
  describe '.new' do
    subject(:exporter) { described_class.new(task) }

    let(:task) { build(:task) }

    it 'assigns task' do
      expect(exporter.instance_variable_get(:@task)).to be task
    end

    it 'assigns files' do
      expect(exporter.instance_variable_get(:@files)).to be_empty
    end

    it 'sets placeholder ModelSolution' do
      expect(exporter.instance_variable_get(:@task).model_solutions).to have_exactly(1).item
    end

    it 'sets params of placeholder ModelSolution' do
      expect(exporter.instance_variable_get(:@task).model_solutions.first).to have_attributes(
        id: 'ms-placeholder',
        files: contain_exactly(have_attributes(content: '', id: 'ms-placeholder-file', used_by_grader: false, visible: 'no'))
      )
    end
  end

  describe '#perform' do
    subject(:perform) { exporter.perform }

    let(:exporter) { described_class.new(task) }
    let(:task) { build(:task) }
    let(:xml_string) { Zip::InputStream.open(perform) { |io| io.get_next_entry.get_input_stream.read } }
    let(:xml) { Nokogiri::XML(xml_string, &:noblanks) }
    let(:xml_task) { xml.xpath('/ns:task', 'ns' => Proforma::XML_NAMESPACE) }

    it { is_expected.to be_a StringIO }

    it 'contains the zipped xml-file' do
      expect { xml_string }.not_to raise_error
    end

    it 'contains through schema validatable xml' do
      expect(Nokogiri::XML::Schema(File.open(Proforma::SCHEMA_PATH)).validate(xml)).to be_empty
    end

    it do
      binding.pry
    end
  end
end
