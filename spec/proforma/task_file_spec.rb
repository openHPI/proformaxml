# frozen_string_literal: true

RSpec.describe Proforma::TaskFile do
  it_behaves_like 'mass assignable', %i[id content filename used_by_grader visible usage_by_lms binary internal_description mimetype]

  describe '#embed?' do
    subject(:embed?) { task_file.embed? }

    let(:task_file) { build(:task_file, :small_content) }

    it { is_expected.to be true }

    context 'when content is very large' do
      let(:task_file) { build(:task_file, :large_content) }

      it { is_expected.to be false }
    end

    context 'when content is nil' do
      let(:task_file) { build(:task_file, content: nil) }

      it { is_expected.to be true }

      it 'does not raise error' do
        expect { embed? }.not_to raise_error
      end
    end
  end
end
