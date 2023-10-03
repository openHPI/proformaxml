# frozen_string_literal: true

FactoryBot.define do
  factory :test, class: 'ProformaXML::Test' do
    sequence(:files) {|n| build_list(:task_file, 1, id: "test_file_#{n}") }
    sequence(:id) {|n| "test_#{n}" }
    title { 'title' }
    test_type { 'test_type' }
    configuration { nil }

    trait(:no_file) do
      files {}
    end

    trait(:populated) do
      title { 'title' }
      description { 'description' }
      internal_description { 'internal_description' }
      files { build_list(:task_file, 1, :populated, :small_content, :text) }
    end

    trait(:with_meta_data) do
      meta_data do
        {
          'test-meta-data' => {
            '@xmlns' => {
              'namespace' => 'custom_namespace.org',
            },
            'namespace:meta' => {
              '$1' => 'data',
            },
            'namespace:nested' => {
              'namespace:foo' => {
                '$1' => 'bar',
              },
              'namespace:test' => {
                'namespace:abc' => {
                  '$1' => '123',
                },
              },
            },
          },
        }
      end
    end

    trait(:with_multiple_files) do
      files { build_list(:task_file, 2, :populated, :small_content, :text) }
    end

    trait(:with_unittest) do
      test_type { 'unittest' }
      configuration do
        {
          'unit:unittest' => {
            '@xmlns' => {
              'unit' => 'urn:proforma:tests:unittest:v1.1',
            },
            '@framework' => 'JUnit',
            '@version' => '4.10',
            'unit:entry-point' => {
              '$1' => 'HelloWorldTest',
            },
          },
        }
      end
    end

    trait(:with_java_checkstyle) do
      test_type { 'java-checkstyle' }
      configuration do
        {
          'check:java-checkstyle' => {
            '@xmlns' => {
              'check' => 'urn:proforma:tests:java-checkstyle:v1.1',
            },
            '@version' => '3.14',
            'check:max-checkstyle-warnings' => {
              '@xmlns' => {
                'unit' => 'urn:proforma:tests:java-checkstyle:v1.1',
              },
              '$1' => '4',
            },
          },
        }
      end
    end

    trait(:with_regexptest) do
      test_type { 'regexptest' }
      configuration do
        {
          'regex:regexptest' => {
            '@xmlns' => {
              'regex' => 'urn:proforma:tests:regexptest:v0.9',
            },
            'regex:entry-point' => {
              '$1' => 'HelloWorldTest',
            },
            'regex:parameter' => {
              '$1' => 'gui',
            },
            'regex:regular-expressions' => {
              'regex:regexp-disallow' => {
                '@case-insensitive' => 'true',
                '@dotall' => 'true',
                '@multiline' => 'true',
                '@free-spacing' => 'true',
                '$1' => 'foobar',
              },
            },
          },
        }
      end
    end

    trait(:with_multiple_custom_configurations) do
      configuration do
        {
          'unit:unittest' => {
            '@xmlns' => {'unit' => 'urn:proforma:tests:unittest:v1.1'},
            '@version' => '4.10',
            '@framework' => 'JUnit',
            'unit:entry-point' => {
              '$1' => 'HelloWorldTest',
            },
          },
          'regex:regexptest' =>
            {
              '@xmlns' => {'regex' => 'urn:proforma:tests:regexptest:v0.9'},
              'regex:entry-point' => {
                '$1' => 'HelloWorldTest',
              },
              'regex:parameter' => {
                '$1' => 'gui',
              },
              'regex:regular-expressions' => {
                'regex:regexp-disallow' => {
                  '$1' => 'foobar',
                  '@dotall' => 'true',
                  '@multiline' => 'true',
                  '@free-spacing' => 'true',
                  '@case-insensitive' => 'true',
                },
              },
            },
          'check:java-checkstyle' => {
            '@xmlns' => {'check' => 'urn:proforma:tests:java-checkstyle:v1.1'},
            '@version' => '3.14',
            'check:max-checkstyle-warnings' => {
              '$1' => '4',
            },
          },
        }
      end
    end
  end
end
