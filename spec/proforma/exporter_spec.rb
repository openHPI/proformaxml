# frozen_string_literal: true

RSpec.describe Proforma::Exporter do
  describe '.new' do
    subject(:exporter) { described_class.new(task) }

    let(:task) { build(:task) }

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

  describe '#perform' do
    subject(:perform) { exporter.perform }

    let(:exporter) { described_class.new(task) }
    let(:task) { build(:task) }

    let(:zip_files) do
      {}.tap do |hash|
        Zip::InputStream.open(perform) do |io|
          while (entry = io.get_next_entry)
            hash[entry.name] = entry.get_input_stream.read
          end
        end
      end
    end

    let(:doc) { Nokogiri::XML(zip_files['task.xml'], &:noblanks) }
    let(:xml) { doc.remove_namespaces! }
    let(:placeholder_file) { task.all_files.filter { |file| file.id == 'ms-placeholder-file' }.first }
    let(:model_solution) { task.model_solutions.first }

    it_behaves_like 'task node'

    it { is_expected.to be_a StringIO }

    it 'contains the zipped xml-file' do
      expect { zip_files['task.xml'] }.not_to raise_error
    end

    it 'contains through schema validatable xml' do
      #use validator call
      expect(Nokogiri::XML::Schema(File.open(Proforma::SCHEMA_PATH)).validate(doc)).to be_empty
    end

    it 'adds version attribute to proglang node' do
      expect(xml.xpath('/task/proglang').attribute('version').value).to eql ''
    end

    it 'adds id attribute to file node' do
      expect(xml.xpath('/task/files/file').attribute('id').value).to eql placeholder_file.id
    end

    it 'adds used-by-grader attribute to file node' do
      expect(xml.xpath('/task/files/file').attribute('used-by-grader').value).to eql placeholder_file.used_by_grader.to_s
    end

    it 'adds visible attribute to file node' do
      expect(xml.xpath('/task/files/file').attribute('visible').value).to eql placeholder_file.visible
    end

    it 'adds id attribute to model-solution node' do
      expect(xml.xpath('/task/model-solutions/model-solution').attribute('id').value).to eql model_solution.id
    end

    it 'adds refid attribute to fileref' do
      expect(
        xml.xpath('/task/model-solutions/model-solution/filerefs/fileref').attribute('refid').value
      ).to eql model_solution.files.first.id
    end

    context 'when a populated task is supplied' do
      let(:task) { build(:task, :populated) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
    end

    context 'when a populated task with embedded text file is supplied' do
      let(:task) { build(:task, :populated, :with_embedded_txt_file) }
      let(:file) { task.all_files.filter { |file| file.id != 'ms-placeholder-file' }.first }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with embedded file', 'txt'
      it_behaves_like 'task node without model-solution with file'
    end

    context 'when a populated task with embedded binary file is supplied' do
      let(:task) { build(:task, :populated, :with_embedded_bin_file) }
      let(:file) { task.all_files.filter { |file| file.id != 'ms-placeholder-file' }.first }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with embedded file', 'bin'
      it_behaves_like 'task node without model-solution with file'
    end

    context 'when a populated task with attached text file is supplied' do
      let(:task) { build(:task, :populated, :with_attached_txt_file) }
      let(:file) { task.all_files.filter { |file| file.id != 'ms-placeholder-file' }.first }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with attached file', 'txt'
      it_behaves_like 'task node without model-solution with file'
    end

    context 'when a populated task with attached binary file is supplied' do
      let(:task) { build(:task, :populated, :with_attached_bin_file) }
      let(:file) { task.all_files.filter { |file| file.id != 'ms-placeholder-file' }.first }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with attached file', 'bin'
      it_behaves_like 'task node without model-solution with file'
    end

    context 'when a populated task with multiple files is supplied' do
      let(:task) { build(:task, :populated, files: build_list(:task_file, 2)) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'

      it 'add two file-nodes to files' do
        expect(xml.xpath('/task/files/file')).to have(3).items
      end
    end

    context 'when a populated task with a model-solution is supplied' do
      let(:task) { build(:task, :populated, :with_model_solution) }
      let(:file) { task.all_files.filter { |file| file.id != 'ms-placeholder-file' }.first }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with embedded file', 'txt'

      it 'adds id attribute to model-solution node' do
        expect(xml.xpath('/task/model-solutions/model-solution').attribute('id').value).to eql model_solution.id
      end

      it 'adds correct refid attribute to fileref' do
        expect(
          xml.xpath('/task/model-solutions/model-solution/filerefs/fileref').attribute('refid').value
        ).to eql xml.xpath('/task/files/file').attribute('id').value
      end

      it 'adds description attribute to model-solution' do
        expect(xml.xpath('/task/model-solutions/model-solution/description').text).to eql model_solution.description
      end

      it 'adds internal-description attribute to model-solution' do
        expect(xml.xpath('/task/model-solutions/model-solution/internal-description').text).to eql model_solution.internal_description
      end

      context 'when model-solution has multiple files' do
        let(:task) { build(:task, :populated, model_solutions: build_list(:model_solution, 1, files: build_list(:task_file, 2))) }
        let(:file) { task.all_files.filter { |file| file.id != 'ms-placeholder-file' }.first }

        it 'adds correct refid attribute to fileref' do
          expect(xml.xpath('/task/files/file')).to have(2).items
        end
      end
    end

    context 'when a populated task with multiple model-solutions is supplied' do
      let(:task) { build(:task, :populated, model_solutions: build_list(:model_solution, 2)) }

      it_behaves_like 'populated task node'

      it 'add two model-solution-nodes to model-solutions' do
        expect(xml.xpath('/task/model-solutions/model-solution')).to have(2).items
      end
    end

    context 'when a populated task with a test is supplied' do
      let(:task) { build(:task, :populated, :with_test) }
      let(:file) { task.all_files.filter { |file| file.id != 'ms-placeholder-file' }.first }
      let(:test) { task.tests.first }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with embedded file', 'txt'
      it_behaves_like 'task node without model-solution with file'

      it_behaves_like 'task node with test'

      it 'adds filerefs node to test-configuration node' do
        expect(xml.xpath('/task/tests/test/test-configuration/filerefs')).to have(1).item
      end

      it 'adds fileref node to fileref node' do
        expect(xml.xpath('/task/tests/test/test-configuration/filerefs/fileref')).to have(1).item
      end

      it 'adds corresponding file to files' do
        expect(
          xml.xpath("/task/files/file[@id='#{xml.xpath('/task/tests/test/test-configuration/filerefs/fileref').attribute('refid').value}']")
        ).to have(1).item
      end

      context 'when test has no referenced file' do
        let(:task) { build(:task, :populated, tests: build_list(:test, 1, :populated, :no_file)) }

        it_behaves_like 'task node with test'

        it 'does not add filerefs node to test-configuration node' do
          expect(xml.xpath('/task/tests/test/test-configuration/filerefs')).to have(0).items
        end
      end

      context 'when test has multiple referenced files' do
        let(:task) { build(:task, :populated, tests: build_list(:test, 1, :populated, files: build_list(:task_file, 2))) }

        it_behaves_like 'task node with test'

        it 'does not add filerefs node to test-configuration node' do
          expect(xml.xpath('/task/tests/test/test-configuration/filerefs')).to have(1).items
        end

        it 'adds fileref node to fileref node' do
          expect(xml.xpath('/task/tests/test/test-configuration/filerefs/fileref')).to have(2).item
        end
      end

      context 'when test has meta-data' do
        let(:task) { build(:task, :populated, tests: build_list(:test, 1, meta_data: {test: 'data', meta: 'data'})) }
        let(:meta_data_node) { doc.xpath('/xmlns:task/xmlns:tests/xmlns:test/xmlns:test-configuration/xmlns:test-meta-data') }

        it_behaves_like 'task node with test'

        it 'adds namespace to task' do
          expect(doc.xpath('/xmlns:task').first.namespaces['xmlns:c']).to eql 'codeharbor'
        end

        it 'adds test-meta-data node to test-configuration node' do
          expect(meta_data_node).to have(1).items
        end

        it 'adds two children nodes to test-meta-data node' do
          expect(meta_data_node.children).to have(2).items
        end

        it 'adds test node with correct namespace to test-meta-data node' do
          expect(meta_data_node.xpath('c:test').text).to eql 'data'
        end

        it 'adds meta node with correct namespace to test-meta-data node' do
          expect(meta_data_node.xpath('c:meta').text).to eql 'data'
        end
      end

      context 'when test has no meta-data' do
        let(:task) { build(:task, :populated, tests: build_list(:test, 1)) }

        it_behaves_like 'task node with test'

        it 'does not add namespace to task' do
          expect(doc.xpath('/xmlns:task').first.namespaces['xmlns:c']).to be_nil
        end

        it 'adds no test-meta-data node to test-configuration node' do
          expect(xml.xpath('/task/tests/test/test-configuration/test-meta-data')).to have(0).items
        end
      end

      context 'when test has is unittest and has extra test-configuration' do
        let(:task) do
          build(:task, :populated, tests: build_list(:test, 1, test_type: 'unittest', configuration: {
                                                       'version' => '1.23', 'framework' => 'rspec', 'entry-point' => 'unit_file_spec.rb'
                                                     }))
        end
        let(:unittest_node) { doc.xpath('/xmlns:task/xmlns:tests/xmlns:test/xmlns:test-configuration').xpath('unit:unittest') }

        it 'adds namespace to task' do
          expect(doc.xpath('/xmlns:task').first.namespaces['xmlns:unit']).to eql 'urn:proforma:tests:unittest:v1.1'
        end

        it 'adds node with correct namespace ' do
          expect(unittest_node).not_to be_nil
        end

        it 'adds entry-poiny node with correct namespace and content' do
          expect(unittest_node.xpath('unit:entry-point').text).to eql 'unit_file_spec.rb'
        end

        it 'adds correct framework-attribute to node' do
          expect(unittest_node.attribute('framework').text).to eql 'rspec'
        end

        it 'adds correct version-attribute to node' do
          expect(unittest_node.attribute('version').text).to eql '1.23'
        end
      end
    end

    context 'when a populated task with multiple tests is supplied' do
      let(:task) { build(:task, :populated, tests: build_list(:test, 2)) }

      it_behaves_like 'populated task node'

      it 'add two test-nodes to tests' do
        expect(xml.xpath('/task/tests/test')).to have(2).items
      end
    end

    context 'when task is invalid' do
      let(:task) { build(:task, :invalid) }

      it 'raises an error' do
        expect { perform }.to raise_error Proforma::PostGenerateValidationError
      end
    end

    context 'when task is minimal and has minimal child objects' do
      let(:task) do
        build(
          :task,
          files: build_list(:task_file, 1),
          tests: build_list(:test, 1),
          model_solutions: build_list(:model_solution, 1)
        )
      end

      it 'does not set lang-attribute for task' do
        expect(xml.xpath('/task').attribute('lang')).to be nil
      end

      it 'does not set parent-uuid-attribute for task' do
        expect(xml.xpath('/task').attribute('parent-uuid')).to be nil
      end

      it 'does not set internal-description for task' do
        expect(xml.xpath('/task/internal-description')).to be_empty
      end

      it 'does not set internal-description for the files' do
        expect(xml.xpath('/task/files/file/internal-description')).to be_empty
      end

      it 'does not set description for model_solution' do
        expect(xml.xpath('/task/model-solutions/model-solution/description')).to be_empty
      end

      it 'does not set internal-description for model_solution' do
        expect(xml.xpath('/task/model-solutions/model-solution/internal-description')).to be_empty
      end

      it 'does not set description for test' do
        expect(xml.xpath('/task/tests/test/description')).to be_empty
      end

      it 'does not set internal-description for test' do
        expect(xml.xpath('/task/tests/test/internal-description')).to be_empty
      end
    end
  end
end
