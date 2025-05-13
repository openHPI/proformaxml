# frozen_string_literal: true

RSpec.describe ProformaXML::Task do
  it_behaves_like 'mass assignable',
    %i[title description internal_description proglang files tests uuid parent_uuid language model_solutions]
  it_behaves_like 'collections mass assignable', %i[files tests model_solutions]

  describe '#all_files' do
    subject { task.all_files }

    let(:task) { build(:task) }

    context 'when task has no files' do
      it { is_expected.to be_empty }
    end

    context 'when task has files' do
      let(:task) { build(:task, files:) }
      let(:files) { build_list(:task_file, 2) }

      it { is_expected.to match_array(files) }
    end

    context 'when task has a model_solution' do
      let(:task) { build(:task, model_solutions:) }
      let(:model_solutions) { [build(:model_solution, files:)] }
      let(:files) { build_list(:task_file, 2) }

      it { is_expected.to match_array(files) }
    end

    context 'when task has a test' do
      let(:task) { build(:task, tests:) }
      let(:tests) { [build(:test, files:)] }
      let(:files) { build_list(:task_file, 2) }

      it { is_expected.to match_array(files) }
    end

    context 'when task has files, model_solutions and tests' do
      let(:task) { build(:task, files: task_files, model_solutions:, tests:) }
      let(:model_solutions) { [build(:model_solution, files: model_solution_files)] }
      let(:tests) { [build(:test, files: test_files)] }

      let(:task_files) { build_list(:task_file, 2) }
      let(:model_solution_files) { build_list(:task_file, 2) }
      let(:test_files) { build_list(:task_file, 2) }

      it { is_expected.to match_array(task_files + model_solution_files + test_files) }

      context 'when a file is assigned multiple times' do
        let(:task_files) { model_solution_files + test_files }

        it { is_expected.to match_array(model_solution_files + test_files) }
      end
    end
  end
end
