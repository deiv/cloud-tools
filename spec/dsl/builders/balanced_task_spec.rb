
require 'spec_helper'

require 'cloud-tools/dsl/exceptions'
require 'cloud-tools/dsl/builders/build_set'

dsl_full = <<EOT
  nodes do
    instance "xlarge"
    count 15
    slots 3
  end

  args do
    no_arch_all
    mode :binary_only
  end
EOT

dsl_lacks_nodes = <<EOT
  task "test" do
    no_arch_all
    mode :binary_only
  end

  args "reference" do
    no_arch_all
    mode :binary_only
    log_id "normal"
  end
EOT

dsl_bad = <<EOT
  nodes do
    instance "xlarge"
    count 15
    slots 3
  end

  agrs "test" do
    no_arch_all
    mode :binary_only
  end
EOT

describe ::Dsl::Builders::BalancedTaskBuilder do

  before do
    @balanced_task_builder = ::Dsl::Builders::BalancedTaskBuilder.new
  end

  describe "when a valid block is evaluated" do

    it "should return a Model::DslBuildSet" do
      @balanced_task_builder.eval_block { eval dsl_full }
      assert_equal ::Dsl::Model::DslBuildSet, @balanced_task_builder.model.class
    end

    it "should generate the correct model" do
      dsl_full_expected_model = ::Dsl::Model::DslBuildSet.new(
        '',
        Nodes.new(CloudTools::Config.instances['xlarge'], 15, 3, [], {}, nil, []),
        { :* => {:no_arch_all=>true, :modes=>[:binary_only]} }
      )

      @balanced_task_builder.eval_block { eval dsl_full }
      assert_equal dsl_full_expected_model, @balanced_task_builder.model
    end
  end

  describe "when no block is evaluated" do

    it "should return an empty Model::DslBuildSet" do
      assert_equal ::Dsl::Model::DslBuildSet, @balanced_task_builder.model.class
      assert_equal "", @balanced_task_builder.model.name
      assert_equal nil, @balanced_task_builder.model.nodes
      assert_equal Hash.new, @balanced_task_builder.model.args
    end
  end

  describe "when a block that lacks required nodes parameter is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @balanced_task_builder.eval_block { eval dsl_lacks_nodes }
      end
    end
  end

  describe "when a invalid block is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @balanced_task_builder.eval_block { eval dsl_bad }
      end
    end
  end

  describe "when a empty block is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @balanced_task_builder.eval_block { eval '' }
      end
    end
  end
end
