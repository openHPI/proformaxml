# frozen_string_literal: true

RSpec.describe 'equal_task matcher' do
  let(:task) { build(:task) }
  let(:task_2) { build(:task) }

  it 'successfully compares two similar tasks' do
    expect(task).to be_an_equal_task_as task_2
  end

  context 'when different classes are submitted' do
    let(:string) { 'hello' }
    let(:integer) { 1234 }

    it 'fails' do
      expect(string).not_to be_an_equal_task_as integer
    end

    it 'provides a useful error message' do
      expect { expect(string).to be_an_equal_task_as integer }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /not equal to/)
    end
  end

  context 'when one task is different' do
    let(:task_2) { build(:task, title: 'different title') }

    it 'fails the comparison' do
      expect(task).not_to be_an_equal_task_as task_2
    end

    it 'provides a useful error message' do
      expect { expect(task).to be_an_equal_task_as task_2 }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /not equal to/)
    end
  end

  context 'when only one task has a file' do
    let(:task_2) { build(:task, files: [build(:task_file)]) }

    it 'fails the comparison' do
      expect(task).not_to be_an_equal_task_as task_2
    end

    it 'provides a useful error message' do
      expect { expect(task).to be_an_equal_task_as task_2 }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /not equal to/)
    end
  end

  context 'when the tasks are complex' do
    let(:task) { build(:task, :with_everything) }
    let(:task_2) { build(:task, :with_everything) }

    before do
      FactoryBot.rewind_sequences
      task
      FactoryBot.rewind_sequences
      task_2
    end

    it 'successfully compares the tasks' do
      expect(task).to be_an_equal_task_as task_2
    end

    context 'with a tiny change in the meta_data' do
      before { task.meta_data['meta-data']['namespace:meta']['$1'] = 'doto' }

      it 'fails' do
        expect(task).not_to be_an_equal_task_as task_2
      end

      it 'provides a useful error message' do
        expect { expect(task).to be_an_equal_task_as task_2 }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /not equal to/)
      end
    end

    context 'with a tiny change in the nested meta_data' do
      before { task.meta_data['meta-data']['namespace:nested']['namespace:test']['namespace:abc']['$1'] = 'doto' }

      it 'fails' do
        expect(task).not_to be_an_equal_task_as task_2
      end

      it 'provides a useful error message' do
        expect { expect(task).to be_an_equal_task_as task_2 }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /not equal to/)
      end
    end

    context 'with a tiny change in a file' do
      before { task.files.first.content += 'a' }

      it 'fails' do
        expect(task).not_to be_an_equal_task_as task_2
      end

      it 'provides a useful error message' do
        expect { expect(task).to be_an_equal_task_as task_2 }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /not equal to/)
      end
    end

    context 'with a tiny change in a model_solution' do
      before { task.model_solutions.first.internal_description += 'a' }

      it 'fails' do
        expect(task).not_to be_an_equal_task_as task_2
      end

      it 'provides a useful error message' do
        expect { expect(task).to be_an_equal_task_as task_2 }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /not equal to/)
      end
    end

    context 'with a tiny change in a test' do
      before { task.tests.first.title += 'a' }

      it 'fails' do
        expect(task).not_to be_an_equal_task_as task_2
      end

      it 'provides a useful error message' do
        expect { expect(task).to be_an_equal_task_as task_2 }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /not equal to/)
      end
    end

    context 'with a tiny change in a test meta_data' do
      before { task.tests.first.meta_data[:test_meta] = 'diti' }

      it 'fails' do
        expect(task).not_to be_an_equal_task_as task_2
      end

      it 'provides a useful error message' do
        expect { expect(task).to be_an_equal_task_as task_2 }.to raise_error(RSpec::Expectations::ExpectationNotMetError, /not equal to/)
      end
    end
  end

  context 'with two similar tasks with 3 files' do
    let(:task) { build(:task, files:) }
    let(:task_2) { build(:task, files: files_2) }

    let(:files) { [build(:task_file, id: 1), build(:task_file, id: 2), build(:task_file, id: files_3_id)] }
    let(:files_3_id) { 3 }
    let(:files_2) { [build(:task_file, id: 1), build(:task_file, id: 2), build(:task_file, id: files_2_3_id)] }
    let(:files_2_3_id) { 3 }

    it 'successfully compares the tasks' do
      expect(task).to be_an_equal_task_as task_2
    end

    context 'when both tasks have two equal files, but are still different' do
      let(:files_3_id) { 2 }
      let(:files_2_3_id) { 1 }

      it 'successfully compares the tasks' do
        expect(task).not_to be_an_equal_task_as task_2
      end
    end
  end
end
