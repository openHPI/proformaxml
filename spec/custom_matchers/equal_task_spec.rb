# frozen_string_literal: true

# Should be reworked / improved!
RSpec.describe 'equal_task matcher' do
  let(:task) { build(:task) }
  let(:task2) { build(:task) }

  it 'successfully compares two similar tasks' do
    expect(task).to be_an_equal_task_as task2
  end

  context 'when one task is different' do
    let(:task2) { build(:task, title: 'different title') }

    it 'fails the comparison' do
      expect(task).not_to be_an_equal_task_as task2
    end
  end
end
