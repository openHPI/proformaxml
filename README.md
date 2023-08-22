# ProformaXML

[![Build Status](https://github.com/openHPI/proformaxml/workflows/CI/badge.svg)](https://github.com/openHPI/proformaxml/actions?query=workflow%3ACI)
[![codecov](https://codecov.io/gh/openHPI/proformaxml/branch/main/graph/badge.svg?token=n1rDXnCezH)](https://codecov.io/gh/openHPI/proformaxml)

This gem offers a Ruby implementation of the [ProFormA XML standard](https://github.com/ProFormA/proformaxml), an XML exchange format for programming exercises. This gem includes a datastructure and XML-(de)serializer.

## Installation

Add these lines to your application's Gemfile:

```ruby
gem 'proformaxml'
```

And then execute:

```
$ bundle
```

Note: Removing support for ancient Ruby or Rails versions will not result in a new major. Please be extra careful when using ancient Ruby or Rails versions and updating gems.

## Usage

Create Task

```ruby
task = ProformaXML::Task.new(title: 'title')
```
Call Exporter to serialize to XML.

```ruby
ProformaXML::Exporter.new(task: task).perform
```
It returns a StringIO of a zip-file which includes the XML and any external files (TaskFiles will be saved in the XML up to a size of 50kb, anything larger will be its own file in the zip)
`ProformaXML::Exporter` has the following optional parameters:
- `custom_namespaces`: expects an array with hashes with the following attributes:
    - `prefix`
    - `uri`
- `version`: sets the ProFormA version of the generated XML

Call Importer to deserialize from XML

```ruby
result = ProformaXML::Importer.new(zip: zip_file).perform
task = result[:task]
custom_namespaces = result[:custom_namespaces]
```
the `zip_file` has to be openable by `Zip::File.open(zip: zip.path)`, otherwise `ProformaXML::InvalidZip` will be raised
`ProformaXML::Importer` has the following optional parameter:
- `expected_version`: if the version of the XML doesn't match this value `ProformaXML::InvalidZip` will be raised

## Example

```ruby
ProformaXML::Task.new(
  title: 'title',
  description: 'description',
  internal_description: 'internal_description',
  proglang: {name: 'proglang_name', version: '123'},
  meta_data: {
    CodeOcean: {
      meta_data_key: 'meta_data_content',
      secrets: {
        server_key: 'the key',
        other_key: 'another key'
      }
    }
  },
  files: [
    ProformaXML::TaskFile.new(
      id: 'file_id_1',
      content: 'public static fileContent(){}',
      filename: 'file_content.java',
      used_by_grader: false,
      visible: 'delayed',
      usage_by_lms: 'edit',
      binary: false,
      internal_description: 'internal_description',
      mimetype: 'text/plain'
    ),
    ProformaXML::TaskFile.new(
      id: 'file_id_2',
      content: 'BINARY IMAGE CONTENT',
      filename: 'image.jpg',
      used_by_grader: false,
      visible: 'yes',
      usage_by_lms: 'display',
      binary: true,
      internal_description: 'internal_description',
      mimetype: 'image/jpeg'
    )
  ],
  tests: [
    ProformaXML::Test.new(
      id: 'test_id_1',
      title: 'test title',
      files: [
        ProformaXML::TaskFile.new(
          id: 'test_file_1',
          content: 'public static assert123(){}',
          filename: 'junit/assert123.java',
          used_by_grader: true,
          visible: 'no',
          binary: false,
          internal_description: 'internal_description',
        )
      ],
      meta_data: {
        CodeOcean: {
          entry_point: 'junit/assert123.java'
        }
      }
    )
  ],
  uuid: '2c8ee23e-fa98-4ea9-b6a5-9a0066ebac1f',
  parent_uuid: 'abf097f5-0df0-468d-8ce4-13460c34cd3b',
  language: 'de',
  model_solutions: [
    ProformaXML::ModelSolution.new(
      id: 'model_solution_id_1',
      files: [
        ProformaXML::TaskFile.new(
          id: 'model_solution_test_id_1',
          content: 'public static fileContent(){ syso("A"); }',
          filename: 'this_is_how_its_done.java',
          used_by_grader: false,
          usage_by_lms: 'display',
          visible: 'delayed',
          binary: false,
          internal_description: 'internal_description'
        )
      ]
    )
  ],
)
```
Generated XML from task above with `custom_namespaces: [{prefix: 'CodeOcean', uri: 'codeocean.openhpi.de'}]`
```xml
<?xml version="1.0" encoding="UTF-8"?>
<task xmlns="urn:proforma:v2.0.1" xmlns:CodeOcean="codeocean.openhpi.de" uuid="2c8ee23e-fa98-4ea9-b6a5-9a0066ebac1f" lang="de" parent-uuid="abf097f5-0df0-468d-8ce4-13460c34cd3b">
  <title>title</title>
  <description>description</description>
  <internal-description>internal_description</internal-description>
  <proglang version="123">proglang_name</proglang>
  <files>
    <file id="file_id_1" used-by-grader="false" visible="delayed" usage-by-lms="edit" mimetype="text/plain">
      <embedded-txt-file filename="file_content.java">public static fileContent(){}</embedded-txt-file>
      <internal-description>internal_description</internal-description>
    </file>
    <file id="file_id_2" used-by-grader="false" visible="yes" usage-by-lms="display" mimetype="image/jpeg">
      <embedded-bin-file filename="image.jpg">QklOQVJZIElNQUdFIENPTlRFTlQ=
      </embedded-bin-file>
      <internal-description>internal_description</internal-description>
    </file>
    <file id="model_solution_test_id_1" used-by-grader="false" visible="delayed" usage-by-lms="display">
      <embedded-txt-file filename="this_is_how_its_done.java">public static fileContent(){ syso("A"); }</embedded-txt-file>
      <internal-description>internal_description</internal-description>
    </file>
    <file id="test_file_1" used-by-grader="true" visible="no">
      <embedded-txt-file filename="junit/assert123.java">public static assert123(){}</embedded-txt-file>
      <internal-description>internal_description</internal-description>
    </file>
  </files>
  <model-solutions>
    <model-solution id="model_solution_id_1">
      <filerefs>
        <fileref refid="model_solution_test_id_1"/>
      </filerefs>
    </model-solution>
  </model-solutions>
  <tests>
    <test id="test_id_1">
      <title>test title</title>
      <test-type/>
      <test-configuration>
        <filerefs>
          <fileref refid="test_file_1"/>
        </filerefs>
        <test-meta-data>
          <CodeOcean:entry_point>junit/assert123.java</CodeOcean:entry_point>
        </test-meta-data>
      </test-configuration>
    </test>
  </tests>
  <meta-data>
    <CodeOcean:meta_data_key>meta_data_content</CodeOcean:meta_data_key>
    <CodeOcean:secrets>
      <CodeOcean:server_key>the key</CodeOcean:server_key>
      <CodeOcean:other_key>another key</CodeOcean:other_key>
    </CodeOcean:secrets>
  </meta-data>
</task>
```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/openHPI/proformaxml. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/openHPI/proformaxml/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in this project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/openHPI/proformaxml/blob/main/CODE_OF_CONDUCT.md).
