# frozen_string_literal: true

RSpec.describe Proforma::Task do
  it_behaves_like 'mass assignable',
                  %i[title description internal_description proglang files tests uuid parent_uuid language model_solutions]
  describe '#all_files' do
    subject { task.all_files }

    let(:task) { build :task }

    context 'when task has no files' do
      it { is_expected.to be_empty }
    end

    context 'when task has files' do
      let(:task) { build :task, files: files }
      let(:files) { build_list :task_file, 2 }

      it { is_expected.to contain_exactly(*files) }
    end

    context 'when task has a model_solution' do
      let(:task) { build :task, model_solutions: model_solutions }
      let(:model_solutions) { [build(:model_solution, files: files)] }
      let(:files) { build_list :task_file, 2 }

      it { is_expected.to contain_exactly(*files) }
    end

    context 'when task has a test' do
      let(:task) { build :task, tests: tests }
      let(:tests) { [build(:test, files: files)] }
      let(:files) { build_list :task_file, 2 }

      it { is_expected.to contain_exactly(*files) }
    end

    context 'when task has files, model_solutions and tests' do
      let(:task) { build :task, files: task_files, model_solutions: model_solutions, tests: tests }
      let(:model_solutions) { [build(:model_solution, files: model_solution_files)] }
      let(:tests) { [build(:test, files: test_files)] }

      let(:task_files) { build_list :task_file, 2 }
      let(:model_solution_files) { build_list :task_file, 2 }
      let(:test_files) { build_list :task_file, 2 }

      it { is_expected.to contain_exactly(*(task_files + model_solution_files + test_files)) }

      context 'when a file is assigned multiple times' do
        let(:task_files) { model_solution_files + test_files }

        it { is_expected.to contain_exactly(*(model_solution_files + test_files)) }
      end
    end
  end
end
