
require 'spec_helper'

require 'cloud-tools/dsl/dsl_syntax'

class DslSyntaxMock
  include ::Dsl::DslSyntax

  def dsl_param(p); end
  def validate_test; end
end

describe ::Dsl::DslSyntax do

  before do
    @dsl_syntax_mock = DslSyntaxMock.new
  end

  describe "when validate_presence is called with null object" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @dsl_syntax_mock.validate_presence nil, "test"
      end
    end
  end

  describe "when validate_presence is called with an object" do
    it "should not raise an InvalidSyntaxError exception" do
      begin
        @dsl_syntax_mock.validate_presence 1, "test"

      rescue ::Dsl::InvalidSyntaxError
        assert false, "Dsl::InvalidSyntaxError raised"
      end
    end
  end

  describe "when a block is evaluated" do

    it "should call 'instance_eval' method" do
      @dsl_syntax_mock.expects(:instance_eval)
      @dsl_syntax_mock.eval_block { eval "dsl_param 'test'" }
    end

    it "should call the dsl named methods" do
      @dsl_syntax_mock.expects(:dsl_param).with('test')
      @dsl_syntax_mock.eval_block { eval "dsl_param 'test'" }
    end

    it "should raise InvalidSyntaxError exception if the dsl syntax is invalid" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @dsl_syntax_mock.eval_block { eval "dsl_param_bad 'test'" }
      end
    end

    it "should call 'validate_model' method if the object supports it" do
      @dsl_syntax_mock.instance_eval do
        def validate_model
          validate_test
        end
      end
      @dsl_syntax_mock.expects(:validate_test)
      @dsl_syntax_mock.eval_block { eval "dsl_param 'test'" }
    end

    it "should not call 'validate_model' method if the object didn't supports it" do
      @dsl_syntax_mock.expects(:validate_test).never
      @dsl_syntax_mock.eval_block { eval "dsl_param 'test'" }
    end
  end
end
