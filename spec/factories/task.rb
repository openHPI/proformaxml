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

    trait(:with_placeholder_model_solution) do
      model_solutions do
        build_list(
          :model_solution, 1, id: 'ms-placeholder',
          files: build_list(:task_file, 1, id: 'ms-placeholder-file', used_by_grader: false, visible: 'no', binary: false)
        )
      end
    end
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
          '@@order' => %w[submission-restrictions],
          'submission-restrictions' => {
            '@@order' => %w[file-restriction description internal-description],
            '@max-size' => '50',
            'file-restriction' => [
              {
                '@@order' => %w[$1],
                '@use' => 'required',
                '@pattern-format' => 'none',
                '$1' => 'restriction1',
              },
              {
                '@@order' => %w[$1],
                '@use' => 'optional',
                '@pattern-format' => 'posix-ere',
                '$1' => 'restriction2',
              },
            ],
            'description' => {
              '@@order' => %w[$1],
              '$1' => 'desc',
            },
            'internal-description' => {
              '@@order' => %w[$1],
              '$1' => 'int-desc',
            },
          },
        }
      end
    end
    trait(:with_2_0_file_restrictions) do
      submission_restrictions do
        {
          '@@order' => %w[submission-restrictions],
          'submission-restrictions' => {
            '@@order' => %w[file-restriction description internal-description],
            '@max-size' => '50',
            'file-restriction' => [
              {
                '@@order' => %w[$1],
                '@required' => 'true',
                '@pattern-format' => 'none',
                '$1' => 'restriction1',
              },
            ],
          },
        }
      end
    end

    trait(:with_external_resources) do
      external_resources do
        {
          '@@order' => %w[external-resources],
          'external-resources' => {
            '@@order' => %w[external-resource],
            '@xmlns' => {'foo' => 'urn:custom:foobar'},
            'external-resource' => [
              {
                '@@order' => %w[internal-description foo:bar],
                '@id' => 'external-resource 1',
                '@reference' => '1',
                '@used-by-grader' => 'true',
                '@visible' => 'delayed',
                '@usage-by-lms' => 'download',
                'internal-description' => {
                  '@@order' => %w[$1],
                  '$1' => 'internal-desc',
                },
                'foo:bar' => {
                  '@@order' => %w[foo:content],
                  '@version' => '4',
                  'foo:content' => {
                    '@@order' => %w[$1],
                    '$1' => 'foobar',
                  },
                },
              },
              {
                '@@order' => %w[internal-description foo:bar],
                '@id' => 'external-resource 2',
                '@reference' => '2',
                '@used-by-grader' => 'false',
                '@visible' => 'no',
                '@usage-by-lms' => 'edit',
                'internal-description' => {
                  '@@order' => %w[$1],
                  '$1' => 'internal-desc',
                },
                'foo:bar' => {
                  '@version' => '5',
                  '@@order' => %w[foo:content],
                  'foo:content' => {
                    '@@order' => %w[$1],
                    '$1' => 'barfoo',
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
          '@@order' => %w[grading-hints],
          'grading-hints' => {
            '@@order' => %w[root],
            'root' => {
              '@@order' => %w[test-ref],
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
    trait(:with_meta_data) do
      meta_data do
        {
          '@@order' => %w[meta-data],
          'meta-data' => {
            '@@order' => %w[namespace:meta namespace:nested],
            '@xmlns' => {'namespace' => 'custom_namespace.org'},
            'namespace:meta' => {
              '@@order' => %w[$1],
              '$1' => 'data',
            },
            'namespace:nested' => {
              '@@order' => %w[namespace:foo namespace:test],
              'namespace:foo' => {
                '@@order' => %w[$1],
                '$1' => 'bar',
              },
              'namespace:test' => {
                '@@order' => %w[namespace:abc],
                'namespace:abc' => {
                  '@@order' => %w[$1],
                  '$1' => '123',
                },
              },
            },
          },
        }
      end
    end

    trait(:invalid) { files { build_list(:task_file, 1, :invalid) } }
  end
end
