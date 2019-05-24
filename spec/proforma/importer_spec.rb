# frozen_string_literal: true

RSpec.describe Proforma::Importer do
  describe '.new' do
    let(:task) { build(:task) }
    let(:zip_file) { Tempfile.new('proforma_test_zip_file') }
    let(:importer) { described_class.new(zip_file) }

    before do
      zip_file.write(Proforma::Exporter.new(task).perform.string)
      zip_file.rewind
    end

    it 'assigns zip' do
      expect(importer.instance_variable_get(:@zip)).to be zip_file
    end

    it 'assigns doc' do
      expect(importer.instance_variable_get(:@doc)).to be_a Nokogiri::XML::Document
    end

    it 'assigns task' do
      expect(importer.instance_variable_get(:@task)).to be_a Proforma::Task
    end
  end

  describe '#perform' do
    subject(:perform) { importer.perform }

    let(:task) { build(:task) }
    # let(:task) { build(:task) }
    let(:zip_file) { Tempfile.new('proforma_test_zip_file') }
    let(:importer) { described_class.new(zip_file) }

    before do
      zip_file.write(Proforma::Exporter.new(task).perform.string)
      zip_file.rewind
    end

    it 'imports an equal task' do
      expect(perform).to be_an_equal_task_as task
    end

    context 'when task is populated' do
      let(:task) { build(:task, :populated) }

      it 'imports an equal task' do
        expect(perform).to be_an_equal_task_as task
      end
    end

    context 'when task has a file' do
      let(:task) { build(:task, :with_embedded_txt_file) }

      it 'imports an equal task' do
        binding.pry
        expect(perform).to be_an_equal_task_as task#???????///
      end
    end
  end
end
