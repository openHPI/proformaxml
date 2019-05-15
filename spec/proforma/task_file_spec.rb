# frozen_string_literal: true

RSpec.describe Proforma::TaskFile do
  it_behaves_like 'mass assignable', %i[id content filename used_by_grader visible usage_by_lms binary internal_description mimetype]

  describe '#embed?' do
    subject { task_file.embed? }

    let(:task_file) { described_class.new content: content }
    let(:content) { 'test' }

    it { is_expected.to be true }

    context 'when content is very large' do
      let(:content) { 'test' * 10**5 }

      it { is_expected.to be false }
    end
  end
end
