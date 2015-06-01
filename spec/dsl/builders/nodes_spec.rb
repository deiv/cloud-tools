
require 'spec_helper'

require 'cloud-tools/dsl/exceptions'
require 'cloud-tools/dsl/builders/nodes'

dsl_full = <<EOT
  instance "xlarge"
  count 15
  slots 3
  securitygroups "sg1"
  tag "Tag1Name", "Tag1Value"
  tag "Tag2Name", "Tag2Value"
EOT

dsl_bad = <<EOT
  instance "xlarge"
  cuunt 15
  slots 3
  securitygroups "sg1"
EOT

describe ::Dsl::Builders::NodesBuilder do

  before do
    @nodes_builder = ::Dsl::Builders::NodesBuilder.new
  end

  describe "when a valid block is evaluated" do

    it "should return a Nodes struct" do
      @nodes_builder.eval_block { eval dsl_full }
      assert_equal Nodes, @nodes_builder.model.class
    end

    it "should generate the correct model" do
      dsl_full_expected_model = Nodes.new(
        Instance.new("xlarge", "m2.xlarge", 0.5),
        15,
        3,
        "sg1",
        { "Tag1Name" => "Tag1Value", "Tag2Name" => "Tag2Value" }
      )

      @nodes_builder.eval_block { eval dsl_full }
      assert_equal dsl_full_expected_model, @nodes_builder.model
    end
  end

  describe "when no block is evaluated" do

    it "should return an empty Nodes" do
      assert_equal Nodes, @nodes_builder.model.class
      assert_equal nil, @nodes_builder.model.instance
      assert_equal nil, @nodes_builder.model.count
      assert_equal nil, @nodes_builder.model.slots
      assert_equal [], @nodes_builder.model.securitygroups
      assert_equal Hash.new, @nodes_builder.model.tags
    end
  end

  %w{instance count slots}.each do |required_param|
    describe "when a block that lacks the required parameter '#{required_param}' is evaluated" do

      it "should raise an InvalidSyntaxError exception" do
        dsl_required = dsl_full.gsub(/^.*#{required_param}.*$/, '')

        assert_raises ::Dsl::InvalidSyntaxError do
          @nodes_builder.eval_block { eval dsl_required }
        end
      end
    end
  end

  describe "when a invalid block is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @nodes_builder.eval_block { eval dsl_bad }
      end
    end
  end

  describe "when a empty block is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @nodes_builder.eval_block { eval '' }
      end
    end
  end
end
