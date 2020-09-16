# Proforma

[![Build Status](https://travis-ci.org/openHPI/proforma.svg?branch=master)](https://travis-ci.org/openHPI/proforma)
[![Code Climate](https://codeclimate.com/github/openHPI/proforma/badges/gpa.svg)](https://codeclimate.com/github/openHPI/proforma)
[![Test Coverage](https://codeclimate.com/github/openHPI/proforma/badges/coverage.svg)](https://codeclimate.com/github/openHPI/proforma)

This gem offers a ruby implementation of https://github.com/ProFormA/proformaxml. Includes a datastructure and XML-(de)serializer.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'proforma', git: 'git://github.com/openHPI/proforma.git', tag: 'v0.5'
```

And then execute:

    $ bundle

## Usage

Create Task
```ruby
task = Proforma::Task.new(title: 'title')
```
Call Exporter to serialize to XML.
```ruby
Proforma::Exporter.new(task).perform
```
It returns a StringIO of a zip-file which includes the XML and any external files (TaskFiles will be saved in the XML up to a size of 50kb, anything larger will be its own file in the zip)

Call Importer to deserialize from XML
```ruby
task = Proforma::Exporter.new(zip_file).perform
```
the zip_file has to be openable by Zip::File.open(zip.path), otherwise Proforma::InvalidZip will be raised

## Example
```ruby
Proforma::Task.new(
  title: 'title',
  description: 'description',
  internal_description: 'internal_description',
  proglang: {name: 'proglang_name', version: '123'},
  files: [
    Proforma::TaskFile.new(
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
    Proforma::TaskFile.new(
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
    Proforma::Test.new(
      id: 'test_id_1',
      title: 'test title',
      files: [
        Proforma::TaskFile.new(
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
        'key' => 'value'
      }
    )
  ],
  uuid: '2c8ee23e-fa98-4ea9-b6a5-9a0066ebac1f',
  parent_uuid: 'abf097f5-0df0-468d-8ce4-13460c34cd3b',
  language: 'de',
  model_solutions: [
    Proforma::ModelSolution.new(
      id: 'model_solution_id_1',
      files: [
        Proforma::TaskFile.new(
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
Generated XML from task above
```xml
<?xml version="1.0" encoding="UTF-8"?>
<task xmlns="urn:proforma:v2.0.1" xmlns:c="codeharbor" uuid="2c8ee23e-fa98-4ea9-b6a5-9a0066ebac1f" lang="de" parent-uuid="abf097f5-0df0-468d-8ce4-13460c34cd3b">
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
          <c:key>value</c:key>
        </test-meta-data>
      </test-configuration>
    </test>
  </tests>
</task>

```
## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/openHPI/proforma.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
