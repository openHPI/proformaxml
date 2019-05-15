# frozen_string_literal: true

RSpec.describe Proforma::Task do
  it_behaves_like 'mass assignable',
                  %i[title description internal_description proglang files tests uuid parent_uuid language model_solutions]
  describe '#all_files' do
    subject { task.all_files }

    let(:task) { described_class.new }

    context 'when task has no files' do
      it { is_expected.to be_empty }
    end

    context 'when task has files' do
      let(:task) { described_class.new files: files }
      let(:files) { [Proforma::TaskFile.new, Proforma::TaskFile.new] }

      it { is_expected.to contain_exactly(*files) }
    end

    context 'when task has a model_solution' do
      let(:task) { described_class.new model_solutions: model_solutions }
      let(:model_solutions) { [Proforma::ModelSolution.new(files: files)] }
      let(:files) { [Proforma::TaskFile.new, Proforma::TaskFile.new] }

      it { is_expected.to contain_exactly(*files) }
    end

    context 'when task has a test' do
      let(:task) { described_class.new tests: tests }
      let(:tests) { [Proforma::Test.new(files: files)] }
      let(:files) { [Proforma::TaskFile.new, Proforma::TaskFile.new] }

      it { is_expected.to contain_exactly(*files) }
    end

    context 'when task has files, model_solutions and tests' do
      let(:task) { described_class.new files: task_files, model_solutions: model_solutions, tests: tests }
      let(:model_solutions) { [Proforma::ModelSolution.new(files: model_solution_files)] }
      let(:tests) { [Proforma::Test.new(files: test_files)] }

      let(:task_files) { [Proforma::TaskFile.new, Proforma::TaskFile.new] }
      let(:model_solution_files) { [Proforma::TaskFile.new, Proforma::TaskFile.new] }
      let(:test_files) { [Proforma::TaskFile.new, Proforma::TaskFile.new] }

      it { is_expected.to contain_exactly(*(task_files + model_solution_files + test_files)) }

      context 'when a file is assigned multiple times' do
        let(:task_files) { model_solution_files + test_files }

        it { is_expected.to contain_exactly(*(model_solution_files + test_files)) }
      end
    end
  end
end
