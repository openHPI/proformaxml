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

      context 'when test has any-configuration' do
        # this should be fixed with a coherent solution after we adjusted the datamodel to support 100% proforma
        let(:importer) { described_class.new(example_zip_file) }
        let(:example_zip_file) { File.open('spec/support/examples/reverse_fixed.zip') }
        let(:ref_task) do
          build(
            :task,
            files: [],
            tests: [
              build(:test, files: [], id: '1', title: 'Compiler Test', test_type: 'java-compilation', configuration: nil),
              build(:test,
                    files: [build(
                      :task_file, content: 'package reverse_task;foobar', id: '1', used_by_grader: true, visible: 'no',
                                  binary: false, filename: 'reverse_task/DummyHelper.java'
                    ), build(
                      :task_file, content: 'package reverse_task;barfoo', id: '2', used_by_grader: true, visible: 'no',
                                  binary: false, filename: 'reverse_task/MyStringTest.java'
                    )],
                    id: '2', title: 'Junit Test DummyHelper', test_type: 'unittest',
                    configuration: {'framework' => 'JUnit', 'version' => '4.12', 'entry-point' => 'reverse_task.MyStringTest',
                                    'type' => 'unittest'})
            ],
            model_solutions: [
              build(:model_solution, id: '1', files: [build(
                :task_file, content: 'package reverse_task;loremipsum', id: '3', used_by_grader: false, visible: 'delayed',
                            binary: false, filename: 'reverse_task/MyString.java'
              )])
            ],
            title: 'Reverse',
            description: 'revert a string',
            proglang: {name: 'java', version: '1.8'},
            language: 'de',
            uuid: 'be81c606-980a-4fdb-96b7-5fadefa464ed'
          )
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
