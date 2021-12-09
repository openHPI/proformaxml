# frozen_string_literal: true

RSpec.describe Proforma::Importer do
  describe '.new' do
    subject(:importer) { described_class.new(zip: zip_file) }

    let(:task) { build(:task) }
    let(:zip_file) { Tempfile.new('proforma_test_zip_file') }

    before do
      zip_file.write(Proforma::Exporter.new(task: task).perform.string.force_encoding('UTF-8'))
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

    it 'does not assign expected_version' do
      expect(importer.instance_variable_get(:@expected_version)).to be_nil
    end

    context 'with a specific expected_version' do
      subject(:importer) { described_class.new(zip: zip_file, expected_version: expected_version) }

      let(:expected_version) { '2.0' }

      it 'assigns expected_version' do
        expect(importer.instance_variable_get(:@expected_version)).to eql '2.0'
      end
    end
  end

  describe '#perform' do
    subject(:perform) { importer.perform }

    let(:imported_task) { perform[:task] }
    let(:imported_namespaces) { perform[:custom_namespaces] }
    let(:task) { build(:task) }
    let!(:ref_task) { task.dup }
    let(:zip_file) { Tempfile.new('proforma_test_zip_file') }
    let(:importer) { described_class.new(zip: zip_file) }
    let(:export_version) {}
    let(:export_namespaces) { [] }

    before do
      zip_file.write(Proforma::Exporter.new(task: task, custom_namespaces: export_namespaces,
                                            version: export_version).perform.string.force_encoding('UTF-8'))
      zip_file.rewind
    end

    it 'successfully imports the task' do
      expect(imported_task).to be_an_equal_task_as ref_task
    end

    it 'evalutates the correct custom_namespaces' do
      expect(imported_namespaces).to eql export_namespaces
    end

    context 'when task is populated' do
      let(:task) { build(:task, :populated) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has proglang, but no version' do
      let(:task) { build(:task, proglang: {name: 'Ruby'}) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has no meta-data' do
      let(:task) { build(:task, meta_data: {}) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has meta-data' do
      let(:export_namespaces) { [{prefix: 'namespace', uri: 'custom_namespace.org'}] }
      let(:task) { build(:task, meta_data: {namespace: {meta: 'data', nested: {test: {abc: '123'}, foo: 'bar'}}}) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has an embedded text file' do
      let(:task) { build(:task, :with_embedded_txt_file) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has an embedded bin file' do
      let(:task) { build(:task, :with_embedded_bin_file) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has an attached text file' do
      let(:task) { build(:task, :with_attached_txt_file) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has an attached bin file' do
      let(:task) { build(:task, :with_attached_bin_file) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has a model_solution' do
      let(:task) { build(:task, :with_model_solution) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has a test' do
      let(:task) { build(:task, :with_test) }
      let(:export_namespaces) { [{prefix: 'test', uri: 'test.com'}] }

      it 'evalutates the correct custom_namespaces' do
        expect(imported_namespaces).to eql export_namespaces
      end

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end

      context 'when test is minimal' do
        let(:task) { build(:task, tests: build_list(:test, 1)) }

        it 'successfully imports the task' do
          expect(imported_task).to be_an_equal_task_as ref_task
        end
      end

      context 'when test has meta-data' do
        let(:export_namespaces) { [{prefix: 'namespace', uri: 'custom_namespace.org'}] }
        let(:task) do
          build(:task, tests: build_list(:test, 1, meta_data: {namespace: {meta: 'data', nested: {test: {abc: '123'}, foo: 'bar'}}}))
        end

        it 'successfully imports the task' do
          expect(imported_task).to be_an_equal_task_as ref_task
        end
      end
    end

    context 'when task has a test and a model_solution' do
      let(:task) { build(:task, :with_test, :with_model_solution) }
      let(:export_namespaces) { [{prefix: 'test', uri: 'test.com'}] }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has a text, a model_solution and 10 embedded files' do
      let(:task) { build(:task, :with_test, :with_model_solution, files: build_list(:task_file, 10, :populated, :small_content, :text)) }
      let(:export_namespaces) { [{prefix: 'test', uri: 'test.com'}] }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has everything set and multiples of every object' do
      let(:task) { build(:task, :populated, files: files, tests: tests, model_solutions: model_solutions) }
      let(:files) { build_list(:task_file, 2, :populated, :small_content, :text) }
      let(:tests) { build_list(:test, 2, :populated, :with_multiple_files) }
      let(:model_solutions) { build_list(:model_solution, 2, :populated, :with_multiple_files) }
      let(:export_namespaces) { [{prefix: 'test', uri: 'test.com'}] }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'with a specific expected_version' do
      let(:importer) { described_class.new(zip: zip_file, expected_version: expected_version) }
      let(:expected_version) { '2.0' }

      context 'when export_version is the same as expected_version' do
        let(:export_version) { expected_version }

        it 'does not raise an error' do
          expect { perform }.not_to raise_error
        end
      end

      context 'when expected_version is different from the export_version' do
        let(:export_version) { '2.0.1' }

        it 'raises an error' do
          expect { perform }.to raise_error Proforma::PreImportValidationError
        end
      end
    end

    context 'with no specific expected_version' do
      context 'when exported_version is set to 2.0' do
        let(:export_version) { '2.0' }

        it 'does not raise an error' do
          expect { perform }.not_to raise_error
        end
      end

      context 'when exported_version is set to 2.0.1' do
        let(:export_version) { '2.0.1' }

        it 'does not raise an error' do
          expect { perform }.not_to raise_error
        end
      end
    end
  end
end
