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

  ### all the unless tests are still missing ###
  ### multiple elements per node are missing ###
  ### refactor eqls to use variables ###
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

    it_behaves_like 'task node'

    it { is_expected.to be_a StringIO }

    it 'contains the zipped xml-file' do
      expect { zip_files['task.xml'] }.not_to raise_error
    end

    it 'contains through schema validatable xml' do
      expect(Nokogiri::XML::Schema(File.open(Proforma::SCHEMA_PATH)).validate(doc)).to be_empty
    end

    it 'adds version attribute to proglang node' do
      expect(xml.xpath('/task/proglang').attribute('version').value).to eql ''
    end
    it 'adds id attribute to file node' do
      expect(xml.xpath('/task/files/file').attribute('id').value).to eql 'ms-placeholder-file'
    end

    it 'adds used-by-grader attribute to file node' do
      expect(xml.xpath('/task/files/file').attribute('used-by-grader').value).to eql 'false'
    end

    it 'adds visible attribute to file node' do
      expect(xml.xpath('/task/files/file').attribute('visible').value).to eql 'no'
    end

    it 'adds id attribute to model-solution node' do
      expect(xml.xpath('/task/model-solutions/model-solution').attribute('id').value).to eql 'ms-placeholder'
    end

    it 'adds refid attribute to fileref' do
      expect(xml.xpath('/task/model-solutions/model-solution/filerefs/fileref').attribute('refid').value).to eql 'ms-placeholder-file'
    end

    context 'when a populated task is supplied' do
      let(:task) { build(:task, :populated) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
    end

    context 'when a populated task with embedded text file is supplied' do
      let(:task) { build(:task, :populated, :with_embedded_txt_file) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with embedded file', 'txt'
      it_behaves_like 'task node without model-solution with file'
    end

    context 'when a populated task with embedded binary file is supplied' do
      let(:task) { build(:task, :populated, :with_embedded_bin_file) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with embedded file', 'bin'
      it_behaves_like 'task node without model-solution with file'
    end

    context 'when a populated task with attached text file is supplied' do
      let(:task) { build(:task, :populated, :with_attached_txt_file) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with attached file', 'txt'
      it_behaves_like 'task node without model-solution with file'
    end

    context 'when a populated task with attached binary file is supplied' do
      let(:task) { build(:task, :populated, :with_attached_bin_file) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with attached file', 'bin'
      it_behaves_like 'task node without model-solution with file'
    end

    context 'when a populated task with a model-solution is supplied' do
      let(:task) { build(:task, :populated, :with_model_solution) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with embedded file', 'txt'

      it 'adds id attribute to model-solution node' do
        expect(xml.xpath('/task/model-solutions/model-solution').attribute('id').value).to eql 'id'
      end

      it 'adds correct refid attribute to fileref' do
        expect(
          xml.xpath('/task/model-solutions/model-solution/filerefs/fileref').attribute('refid').value
        ).to eql xml.xpath('/task/files/file').attribute('id').value
      end

      it 'adds description attribute to model-solution' do
        expect(xml.xpath('/task/model-solutions/model-solution/description').text).to eql 'description'
      end

      it 'adds internal-description attribute to model-solution' do
        expect(xml.xpath('/task/model-solutions/model-solution/internal-description').text).to eql 'internal_description'
      end
    end

    # test without required params (eg files are not required by schema)
    context 'when a populated task with a test is supplied' do
      let(:task) { build(:task, :populated, :with_test) }

      it_behaves_like 'task node'
      it_behaves_like 'populated task node'
      it_behaves_like 'task node with embedded file', 'txt'
      it_behaves_like 'task node without model-solution with file'

      it 'adds test node to tests' do
        expect(xml.xpath('/task/tests/test')).to have(1).item
      end

      it 'adds id attribute to test node' do
        expect(xml.xpath('/task/tests/test').attribute('id').value).to eql 'id'
      end

      it 'adds content to title node' do
        expect(xml.xpath('/task/tests/test/title').text).to eql 'title'
      end

      it 'adds content to description node' do
        expect(xml.xpath('/task/tests/test/description').text).to eql 'description'
      end

      it 'adds content to internal-description node' do
        expect(xml.xpath('/task/tests/test/internal-description').text).to eql 'internal_description'
      end

      it 'adds content to test-type node' do
        expect(xml.xpath('/task/tests/test/test-type').text).to eql 'test_type'
      end

      it 'adds test-configuration node to test node' do
        expect(xml.xpath('/task/tests/test/test-configuration')).to have(1).item
      end

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

      it 'adds test-meta-data node to test-configuration node' do
        expect(xml.xpath('/task/tests/test/test-configuration/test-meta-data')).to have(1).item
      end

      it 'adds meta-data nodes to test-meta-data node' do
        expect(xml.xpath('/task/tests/test/test-configuration/test-meta-data').children).to have(task.tests.first.meta_data.count).items
      end

      it 'adds namespace to task' do
        expect(doc.xpath('/xmlns:task').first.namespaces['xmlns:c']).to eql 'codeharbor'
      end

      it 'adds correct meta-data to meta-data nodes' do
        expect(xml.xpath("/task/tests/test/test-configuration/test-meta-data/#{task.tests.first.meta_data.first[0]}").text).to eql task.tests.first.meta_data.first[1]
      end
    end
  end
end
