# frozen_string_literal: true

require 'rspec'

RSpec.describe ProformaXML::TransformTask do
  describe '.new' do
    subject(:exporter) { described_class.new(task:, from_version:, to_version:) }

    let(:task) { build(:task) }
    let(:from_version) { '2.0' }
    let(:to_version) { '2.1' }

    it 'assigns task' do
      expect(exporter.instance_variable_get(:@task)).to be task
    end

    it 'assigns from_version' do
      expect(exporter.instance_variable_get(:@from_version)).to be '2.0'
    end

    it 'assigns to_version' do
      expect(exporter.instance_variable_get(:@to_version)).to be '2.1'
    end
  end

  describe '.call' do
    subject(:call) { described_class.call(task:, from_version:, to_version:) }

    let(:zip_file) { ProformaXML::Exporter.call(task:, version: to_version) }
    let(:zip_content) do
      {}.tap do |hash|
        Zip::InputStream.open(zip_file) do |io|
          while (entry = io.get_next_entry)
            hash[entry.name] = entry.get_input_stream.read
          end
        end
      end
    end
    let(:doc) { Nokogiri::XML(zip_content['task.xml'], &:noblanks) }

    shared_examples 'validatable task' do
      it 'does not have any validation errors' do
        call
        expect(ProformaXML::Validator.call(doc:, expected_version: to_version)).to be_empty
      end
    end

    context 'with from 2.0 to 2.1' do
      let(:from_version) { '2.0' }
      let(:to_version) { '2.1' }
      let(:task) { build(:task, :with_2_0_file_restrictions) }

      it 'transforms file_restriction' do
        expect { call }.to change { task.submission_restrictions['submission-restrictions']['file-restriction'][0] }
          .from({'$1' => 'restriction1', '@@order' => ['$1'], '@pattern-format' => 'none', '@required' => 'true'})
          .to({'$1' => 'restriction1', '@@order' => ['$1'], '@pattern-format' => 'none', '@use' => 'required'})
      end

      context 'with model solution placehoder' do
        let(:task) { build(:task, :with_placeholder_model_solution) }

        it 'removes model solution placeholder' do
          expect { call }.to change(task, :model_solutions)
            .from([have_attributes(id: 'ms-placeholder', files: include(have_attributes(id: 'ms-placeholder-file')))])
            .to([])
        end
      end

      it_behaves_like 'validatable task'
    end

    context 'with from 2.1 to 2.0' do
      let(:from_version) { '2.1' }
      let(:to_version) { '2.0' }
      let(:task) { build(:task, :with_submission_restrictions) }

      it 'transforms file_restriction' do
        expect { call }.to change { task.submission_restrictions['submission-restrictions']['file-restriction'][0] }
          .from({'$1' => 'restriction1', '@@order' => ['$1'], '@pattern-format' => 'none', '@use' => 'required'})
          .to({'$1' => 'restriction1', '@@order' => ['$1'], '@pattern-format' => 'none', '@required' => 'true'})
      end

      it 'removes description and internal-description from submission-restrictions' do
        expect { call }.to change { task.submission_restrictions['submission-restrictions'].keys }
          .from(include('description', 'internal-description'))
          .to(not_include('description', 'internal-description'))
      end

      context 'without model_solutions' do
        it 'adds a model solution placeholder' do
          expect { call }.to change(task, :model_solutions)
            .from([])
            .to([have_attributes(id: 'ms-placeholder', files: include(have_attributes(id: 'ms-placeholder-file')))])
        end
      end

      context 'with model_solutions' do
        let(:task) { build(:task, :with_model_solution) }

        it 'does not adds a model solution placeholder' do
          expect { call }.not_to change(task, :model_solutions)
        end
      end

      it_behaves_like 'validatable task'
    end
  end
end
