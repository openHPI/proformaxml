# frozen_string_literal: true

FactoryBot.define do
  factory :task, class: 'ProformaXML::Task' do
    trait(:populated) do
      title { 'title' }
      description { 'description' }
      internal_description { 'internal_description' }
      proglang { {name: 'Ruby', version: '1'} }
      uuid { 'uuid' }
      parent_uuid { 'parent_uuid' }
      language { 'language' }
    end

    trait(:with_embedded_txt_file) { files { build_list(:task_file, 1, :populated, :small_content, :text) } }
    trait(:with_multiple_embedded_txt_files) { files { build_list(:task_file, 5, :populated, :small_content, :text) } }
    trait(:with_embedded_bin_file) { files { build_list(:task_file, 1, :populated, :small_content, :binary) } }
    trait(:with_attached_txt_file) { files { build_list(:task_file, 1, :populated, :large_content, :text) } }
    trait(:with_attached_bin_file) { files { build_list(:task_file, 1, :populated, :large_content, :binary) } }
    trait(:with_meta_data) { meta_data { {namespace: {meta: 'data', nested: {test: {abc: '123'}, foo: 'bar'}}} } }

    trait(:with_model_solution) { model_solutions { build_list(:model_solution, 1, :populated) } }
    trait(:with_test) { tests { build_list(:test, 1, :populated) } }
    trait(:with_test_with_meta_data) { tests { build_list(:test, 1, :populated, :with_meta_data) } }

    trait(:with_everything) do
      with_multiple_embedded_txt_files
      with_model_solution
      with_test_with_meta_data
      with_meta_data
    end

    trait(:with_submission_restrictions) do
      submission_restrictions do
        {
          'submission-restrictions' => {
            '@max-size' => '50',
            'file-restriction' => [
              {
                '@use' => 'required',
                '@pattern-format' => 'none',
                '$1' => 'restriction1',
              },
              {
                '@use' => 'optional',
                '@pattern-format' => 'posix-ere',
                '$1' => 'restriction2',
              },
            ],
            'description' => {
              '$1' => 'desc',
            },
            'internal-description' => {
              '$1' => 'int-desc',
            },
          },
        }
      end
    end

    trait(:with_external_resources) do
      external_resources do
        {
          'external-resources' => {
            'external-resource' => [
              {
                '@id' => 'external-resource 1',
                '@reference' => '1',
                '@used-by-grader' => 'true',
                '@visible' => 'delayed',
                '@usage-by-lms' => 'download',
                'internal-description' => {
                  '$1' => 'internal-desc',
                },
                'foo:bar' => {
                  '@xmlns' => {
                    'foo' => 'urn:custom:foobar',
                  },
                  '@version' => '4',
                  'foo:content' => {
                    '@xmlns' => {
                      'foo' => 'urn:custom:foobar',
                    }, '$1' => 'foobar'
                  },
                },
              },
              {
                '@id' => 'external-resource 2',
                '@reference' => '2',
                '@used-by-grader' => 'false',
                '@visible' => 'no',
                '@usage-by-lms' => 'edit',
                'internal-description' => {
                  '$1' => 'internal-desc',
                },
                'foo:bar' => {
                  '@xmlns' => {
                    'foo' => 'urn:custom:foobar',
                  },
                  '@version' => '5',
                  'foo:content' => {
                    '@xmlns' => {
                      'foo' => 'urn:custom:foobar',
                    }, '$1' => 'barfoo'
                  },
                },
              },
            ],
          },
        }
      end
    end

    trait(:with_grading_hints) do
      grading_hints do
        {
          'grading-hints' => {
            'root' => {
              '@function' => 'sum',
              'test-ref' => [
                {
                  '@ref' => '1',
                  '@weight' => '0',
                },
                {
                  '@ref' => '2',
                  '@weight' => '1',
                },
              ],
            },
          },
        }
      end
    end

    trait(:invalid) { files { build_list(:task_file, 1, :invalid) } }
  end
end
