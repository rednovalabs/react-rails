require 'test_helper'
require 'fileutils'

# Sprockets is inserting a newline after the docblock for some reason...
EXPECTED_JS = <<eos
React.createElement("div", null);
eos

EXPECTED_JS_2 = <<eos
(function() {
  var Component;

  Component = React.createClass({displayName: "Component",
    render: function() {
      return React.createElement(ExampleComponent, {videos:this.props.videos} );
    }
  });

  window.Component = Component;
}).call(this);
eos

class NullTransformer
  def initialize(options={}); end
  def transform(code)
    "TRANSFORMED CODE!;\n"
  end
end

class JSXTransformTest < ActionDispatch::IntegrationTest
  setup do
    reset_transformer
  end

  teardown do
    reset_transformer
  end

  test 'asset pipeline should transform JSX' do
    get '/assets/example.js'
    assert_response :success

    assert_equal EXPECTED_JS.gsub(/\s/, ''), @response.body.gsub(/\s/, '')
  end

  test 'asset pipeline should transform JSX + Coffeescript' do
    get '/assets/example2.js'
    assert_response :success
    # Different coffee-script may generate slightly different outputs,
    # as some version inserts an extra "\n" at the beginning.
    # Because appraisal is used, multiple versions of coffee-script are treated
    # together. Remove all spaces to make test pass.
    assert_equal EXPECTED_JS_2.gsub(/\s/, ''), @response.body.gsub(/\s/, '')
  end

  test 'use a custom transformer' do
    React::JSX.transformer_class = NullTransformer
    manually_expire_asset('example2.js')
    get '/assets/example2.js'
    assert_equal "TRANSFORMED CODE!;\n", @response.body
  end

  def test_babel_transformer_accepts_babel_transformation_options
    React::JSX.transform_options = {blacklist: ['spec.functionName', 'validation.react', "strict"]}
    get '/assets/example.js'
    assert_response :success

    assert !@response.body.include?('strict')
  end

  class AmdOptions
    def self.call(input)
      {
        modules: "amd",
        moduleId: "this_was_not_possible_before/#{input[:name]}",
      }
    end
  end

  def test_babel_transformer_can_provide_per_file_options_with_a_proc
    React::JSX.transform_options = AmdOptions
    get '/assets/amd_example.js'
    assert_response :success
    assert response.body.include?('define("this_was_not_possible_before/amd_example"')
  end
end
