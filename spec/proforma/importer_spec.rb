# frozen_string_literal: true

RSpec.describe Proforma::Importer do
  describe '.new' do
    subject(:importer) { described_class.new(zip_file) }

    let(:task) { build(:task) }
    let(:zip_file) { Tempfile.new('proforma_test_zip_file') }

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

    it 'does not assign expected_version' do
      expect(importer.instance_variable_get(:@expected_version)).to be_nil
    end

    context 'with a specific expected_version' do
      subject(:importer) { described_class.new(zip_file, expected_version) }

      let(:expected_version) { '2.0' }

      it 'does not assign expected_version' do
        expect(importer.instance_variable_get(:@expected_version)).to eql '2.0'
      end
    end
  end

  describe '#perform' do
    subject(:perform) { importer.perform }

    let(:task) { build(:task) }
    let!(:ref_task) { task.dup }
    let(:zip_file) { Tempfile.new('proforma_test_zip_file') }
    let(:importer) { described_class.new(zip_file) }

    before do
      zip_file.write(Proforma::Exporter.new(task).perform.string)
      zip_file.rewind
    end

    it { is_expected.to be_an_equal_task_as ref_task }

    context 'when task is populated' do
      let(:task) { build(:task, :populated) }

      it { is_expected.to be_an_equal_task_as ref_task }
    end

    context 'when task has proglang, but no version' do
      let(:task) { build(:task, proglang: {name: 'Ruby'}) }

      it { is_expected.to be_an_equal_task_as ref_task }
    end

    context 'when task has an embedded text file' do
      let(:task) { build(:task, :with_embedded_txt_file) }

      it { is_expected.to be_an_equal_task_as ref_task }
    end

    context 'when task has an embedded bin file' do
      let(:task) { build(:task, :with_embedded_bin_file) }

      it { is_expected.to be_an_equal_task_as ref_task }
    end

    context 'when task has an attached text file' do
      let(:task) { build(:task, :with_attached_txt_file) }

      it { is_expected.to be_an_equal_task_as ref_task }
    end

    context 'when task has an attached bin file' do
      let(:task) { build(:task, :with_attached_bin_file) }

      it { is_expected.to be_an_equal_task_as ref_task }
    end

    context 'when task has a model_solution' do
      let(:task) { build(:task, :with_model_solution) }

      it { is_expected.to be_an_equal_task_as ref_task }
    end

    context 'when task has a test' do
      let(:task) { build(:task, :with_test) }

      it { is_expected.to be_an_equal_task_as ref_task }

      context 'when test is minimal' do
        let(:task) { build(:task, tests: build_list(:test, 1)) }

        it { is_expected.to be_an_equal_task_as ref_task }
      end

      context 'when test has unittest test-configuration' do
        let(:task) do
          build(:task, tests: build_list(:test, 1, test_type: 'unittest', configuration: {
                                           'version' => '1.23', 'framework' => 'rspec', 'entry-point' => 'unit_file_spec.rb'
                                         }))
        end

        it { is_expected.to be_an_equal_task_as ref_task }
      end
    end

    context 'when task has a text and a model_solution' do
      let(:task) { build(:task, :with_test, :with_model_solution) }

      it { is_expected.to be_an_equal_task_as ref_task }
    end

    context 'when task has a text, a model_solution and 10 embedded files' do
      let(:task) { build(:task, :with_test, :with_model_solution, files: build_list(:task_file, 10, :populated, :small_content, :text)) }

      it { is_expected.to be_an_equal_task_as ref_task }
    end

    context 'when task has everything set and multiples of every object' do
      let(:task) { build(:task, :populated, files: files, tests: tests, model_solutions: model_solutions) }
      let(:files) { build_list(:task_file, 2, :populated, :small_content, :text) }
      let(:tests) { build_list(:test, 2, :populated, files: build_list(:task_file, 2, :populated, :large_content)) }
      let(:model_solutions) do
        build_list(:model_solution, 2, :populated, files: build_list(:task_file, 2, :populated, :binary, :small_content))
      end

      it { is_expected.to be_an_equal_task_as ref_task }
    end
  end
end
