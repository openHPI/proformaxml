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

    context 'when task has an embedded text file' do
      let(:task) { build(:task, :with_embedded_txt_file) }

      it 'imports an equal task' do
        expect(perform).to be_an_equal_task_as task
      end
    end

    context 'when task has an embedded bin file' do
      let(:task) { build(:task, :with_embedded_bin_file) }

      it 'imports an equal task' do
        expect(perform).to be_an_equal_task_as task
      end
    end

    context 'when task has an attached text file' do
      let(:task) { build(:task, :with_attached_txt_file) }

      it 'imports an equal task' do
        expect(perform).to be_an_equal_task_as task
      end
    end

    context 'when task has an attached bin file' do
      let(:task) { build(:task, :with_attached_bin_file) }

      it 'imports an equal task' do
        expect(perform).to be_an_equal_task_as task
      end
    end

    context 'when task has a model_solution' do
      let(:task) { build(:task, :with_model_solution) }

      it 'imports an equal task' do
        expect(perform).to be_an_equal_task_as task
      end
    end

    context 'when task has a test' do
      let(:task) { build(:task, :with_test) }

      it 'imports an equal task' do
        expect(perform).to be_an_equal_task_as task
      end

      context 'when test is minimal' do
        let(:task) { build(:task, tests: build_list(:test, 1)) }

        it 'imports an equal task' do
          expect(perform).to be_an_equal_task_as task
        end
      end
    end

    context 'when task has a text and a model_solution' do
      let(:task) { build(:task, :with_test, :with_model_solution) }

      it 'imports an equal task' do
        expect(perform).to be_an_equal_task_as task
      end
    end

    context 'when task has a text, a model_solution and 10 embedded files' do
      let(:task) { build(:task, :with_test, :with_model_solution, files: build_list(:task_file, 10, :populated, :small_content, :text)) }

      it 'imports an equal task' do
        expect(perform).to be_an_equal_task_as task
      end
    end

    context 'when task has everything set and multiples of every object' do
      let(:task) { build(:task, :populated, files: files, tests: tests, model_solutions: model_solutions) }
      let(:files) { build_list(:task_file, 2, :populated, :small_content, :text) }
      let(:tests) { build_list(:test, 2, :populated, files: build_list(:task_file, 2, :populated, :large_content)) }
      let(:model_solutions) do
        build_list(:model_solution, 2, :populated, files: build_list(:task_file, 2, :populated, :binary, :small_content))
      end

      it 'imports an equal task' do
        expect(perform).to be_an_equal_task_as task
      end
    end
  end
end
