# frozen_string_literal: true

RSpec.describe ProformaXML::Importer do
  describe '.new' do
    subject(:importer) { described_class.new(zip: zip_file) }

    let(:task) { build(:task) }
    let(:zip_file) { Tempfile.new('proforma_test_zip_file') }

    before do
      zip_file.write(ProformaXML::Exporter.call(task:).string.force_encoding('UTF-8'))
      zip_file.rewind
    end

    it 'assigns zip' do
      expect(importer.instance_variable_get(:@zip)).to be zip_file
    end

    it 'assigns doc' do
      expect(importer.instance_variable_get(:@doc)).to be_a Nokogiri::XML::Document
    end

    it 'assigns task' do
      expect(importer.instance_variable_get(:@task)).to be_a ProformaXML::Task
    end

    it 'does not assign expected_version' do
      expect(importer.instance_variable_get(:@expected_version)).to be_nil
    end

    context 'with a specific expected_version' do
      subject(:importer) { described_class.new(zip: zip_file, expected_version:) }

      let(:expected_version) { '2.0' }

      it 'assigns expected_version' do
        expect(importer.instance_variable_get(:@expected_version)).to eql '2.0'
      end
    end

    context 'when zip-file does not contain task.xml' do
      before do
        zip_file.write('Foobar')
        zip_file.rewind
      end

      it 'raises correct error' do
        expect { importer }.to raise_error(ProformaXML::PreImportValidationError, /no task_xml found/)
      end
    end
  end

  describe '#perform' do
    subject(:perform) { described_class.call(zip: zip_file) }

    let(:imported_task) { perform }
    let(:task) { build(:task) }
    let!(:ref_task) { task.dup }
    let(:zip_file) { Tempfile.new('proforma_test_zip_file') }
    let(:export_version) {}

    before do |test|
      unless test.metadata[:skip_export]
        zip_file.write(ProformaXML::Exporter.call(task:, version: export_version).string.force_encoding('UTF-8'))
        zip_file.rewind
      end
    end

    it 'successfully imports the task' do
      expect(imported_task).to be_an_equal_task_as ref_task
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
      let(:task) { build(:task, :with_meta_data) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has submission_restrictions' do
      let(:task) { build(:task, :with_submission_restrictions) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has external_resources' do
      let(:task) { build(:task, :with_external_resources) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has grading_hints' do
      let(:task) { build(:task, :with_grading_hints) }

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
        let(:task) do
          build(:task, tests: build_list(:test, 1, :with_meta_data))
        end

        it 'successfully imports the task' do
          expect(imported_task).to be_an_equal_task_as ref_task
        end
      end

      context 'when test-configuration has custom data' do
        let(:task) { build(:task, tests:) }
        let(:tests) { build_list(:test, 1, :with_unittest) }

        it 'successfully imports the task' do
          expect(imported_task).to be_an_equal_task_as ref_task
        end

        context 'with multiple custom data entries' do
          let(:tests) { build_list(:test, 1, :with_multiple_custom_configurations) }

          it 'successfully imports the task' do
            expect(imported_task).to be_an_equal_task_as ref_task
          end
        end
      end
    end

    context 'when task has a test and a model_solution' do
      let(:task) { build(:task, :with_test, :with_model_solution) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has a test, a model_solution and 10 embedded files' do
      let(:task) { build(:task, :with_test, :with_model_solution, files: build_list(:task_file, 10, :populated, :small_content, :text)) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'when task has everything set and multiples of every object' do
      let(:task) { build(:task, :populated, files:, tests:, model_solutions:) }
      let(:files) { build_list(:task_file, 2, :populated, :small_content, :text) }
      let(:tests) { build_list(:test, 2, :populated, :with_multiple_files) }
      let(:model_solutions) { build_list(:model_solution, 2, :populated, :with_multiple_files) }

      it 'successfully imports the task' do
        expect(imported_task).to be_an_equal_task_as ref_task
      end
    end

    context 'with a specific expected_version' do
      subject(:perform) { described_class.call(zip: zip_file, expected_version:) }

      let(:expected_version) { '2.0' }

      context 'when export_version is the same as expected_version' do
        let(:export_version) { expected_version }

        it 'does not raise an error' do
          expect { perform }.not_to raise_error
        end
      end

      context 'when expected_version is different from the export_version' do
        let(:export_version) { '2.1' }

        it 'raises an error' do
          expect { perform }.to raise_error ProformaXML::PreImportValidationError, /No matching global declaration available for the validation root/
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

      context 'when exported_version is set to 2.1' do
        let(:export_version) { '2.1' }

        it 'does not raise an error' do
          expect { perform }.not_to raise_error
        end
      end
    end

    context 'with prefixed ProFormA namespace' do
      before do
        zip_file.write(Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry('task.xml')
          zio.write xml_file.read
        end.string.force_encoding('UTF-8'))
        zip_file.rewind
      end

      let(:expected_meta_data) do
        {
          '@@order' => ['meta-data'],
          'meta-data' => {
            '@@order' => ['CodeOcean:files'],
            '@xmlns' => {'CodeOcean' => 'codeocean.openhpi.de'},
            'CodeOcean:files' => {
              '@@order' => ['CodeOcean:CO-42'],
              'CodeOcean:CO-42' => {
                '@@order' => ['CodeOcean:role'],
                'CodeOcean:role' => {
                  '$1' => 'main_file', '@@order' => ['$1']
                },
              },
            },
          },
        }
      end

      let(:xml_file) { file_fixture('task_with_prefixed_proforma_namespace.xml') }

      it 'does not raise an error', :skip_export do
        expect { perform }.not_to raise_error
      end

      it 'successfully imports the task' do # rubocop:disable RSpec/ExampleLength
        expect(imported_task).to have_attributes(
          files: have_exactly(2).items,
          model_solutions: have_exactly(1).item,
          tests: have_exactly(1).item,
          meta_data: expected_meta_data
        )
      end
    end

    context 'with file referenced in multiple tests' do
      before do
        zip_file.write(Zip::OutputStream.write_buffer do |zio|
          zio.put_next_entry('task.xml')
          zio.write xml_file.read
        end.string.force_encoding('UTF-8'))
        zip_file.rewind
      end

      let(:xml_file) { file_fixture('task_with_referenced_file_in_multiple_tests.xml') }

      it 'does not raise an error', :skip_export do
        expect { perform }.not_to raise_error
      end

      it 'successfully imports the task' do
        expect(imported_task).to have_attributes(
          files: have_exactly(1).items,
          model_solutions: have_exactly(0).items,
          tests: have_exactly(2).items
        )
      end

      it 'imports test-files correctly' do
        expect(imported_task.tests.map(&:files).flatten).to have_exactly(2).items.and(not_include(nil))
      end
    end

    context 'with specific export_version' do
      before do
        allow(ProformaXML::TransformTask).to(receive(:call))
        perform
      end

      context 'when exported version is 2.0' do
        let(:export_version) { '2.0' }

        it 'calls TransformTask Service with correct arguments' do
          expect(ProformaXML::TransformTask).to have_received(:call).with(task: an_instance_of(ProformaXML::Task), from_version: '2.0', to_version: '2.1')
        end
      end

      context 'when exported version is 2.1' do
        let(:export_version) { '2.1' }

        it 'calls TransformTask Service with correct arguments' do
          expect(ProformaXML::TransformTask).not_to have_received(:call)
        end
      end
    end
  end
end
