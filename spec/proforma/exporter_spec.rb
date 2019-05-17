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
    let(:zip_files) do
      file_hash = {}
      Zip::InputStream.open(perform) do |io|
        while (entry = io.get_next_entry)
          file_hash[entry.name] = entry.get_input_stream.read
        end
      end
      file_hash
    end
    let(:doc) { Nokogiri::XML(zip_files['task.xml']) }
    let(:xml) { doc.remove_namespaces! }

    it_behaves_like 'task node'

    it { is_expected.to be_a StringIO }

    it 'contains the zipped xml-file' do
      expect { zip_files['task.xml'] }.not_to raise_error
    end

    it 'contains through schema validatable xml' do
      expect(Nokogiri::XML::Schema(File.open(Proforma::SCHEMA_PATH)).validate(doc)).to be_empty
    end

    it 'adds version attribute to proglang node' do
      expect(xml.xpath('/task/proglang').attribute('version').value).to eql ''
    end
    it 'adds id attribute to file node' do
      expect(xml.xpath('/task/files/file').attribute('id').value).to eql 'ms-placeholder-file'
    end

    it 'adds used-by-grader attribute to file node' do
      expect(xml.xpath('/task/files/file').attribute('used-by-grader').value).to eql 'false'
    end

    it 'adds visible attribute to file node' do
      expect(xml.xpath('/task/files/file').attribute('visible').value).to eql 'no'
    end

    it 'adds id attribute to model-solution node' do
      expect(xml.xpath('/task/model-solutions/model-solution').attribute('id').value).to eql 'ms-placeholder'
    end

    it 'adds refid attribute to fileref' do
      expect(xml.xpath('/task/model-solutions/model-solution/filerefs/fileref').attribute('refid').value).to eql 'ms-placeholder-file'
    end

    context 'when a populated task is supplied' do
      let(:task) { build(:task, :populated) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
    end

    context 'when a populated task with embedded text file is supplied' do
      let(:task) { build(:task, :populated, :with_embedded_txt_file) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with embedded file', 'txt'
    end

    context 'when a populated task with embedded binary file is supplied' do
      let(:task) { build(:task, :populated, :with_embedded_bin_file) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with embedded file', 'bin'
    end

    context 'when a populated task with attached text file is supplied' do
      let(:task) { build(:task, :populated, :with_attached_txt_file) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with attached file', 'txt'
    end

    context 'when a populated task with attached binary file is supplied' do
      let(:task) { build(:task, :populated, :with_attached_bin_file) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with attached file', 'bin'
    end
  end
end
