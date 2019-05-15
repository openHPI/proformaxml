# frozen_string_literal: true

RSpec.describe Proforma::Exporter do
  describe '.new' do
    subject(:exporter) { described_class.new(task) }

    let(:task) { Proforma::Task.new }

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
end
