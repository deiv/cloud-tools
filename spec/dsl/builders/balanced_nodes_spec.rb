
require 'spec_helper'

require 'cloud-tools/model'
require 'cloud-tools/dsl/exceptions'
require 'cloud-tools/dsl/builders/balanced_nodes'

dsl_full = <<EOT
  mid_point 1600

  upper_task do
    nodes do
      instance "xlarge"
      count 15
      slots 3
    end

    args do
      mode :parallel
    end
  end

  lower_task do
    nodes do
      instance "medium"
      count 30
      slots 6
    end
  end
EOT

dsl_lacks_one_task = <<EOT
  mid_point 1600

  upper_task do
    nodes do
      instance "xlarge"
      count 15
      slots 3
    end

    args do
      mode :parallel
    end
  end
EOT

dsl_lacks_midpoint = <<EOT
  upper_task do
    nodes do
      instance "xlarge"
      count 15
      slots 3
    end

    args do
      mode :parallel
    end
  end

  lower_task do
    nodes do
      instance "medium"
      count 30
      slots 6
    end
  end
EOT

dsl_lacks_one_task = <<EOT
  mid_point 1600

  upper_task do
    nodes do
      instance "xlarge"
      count 15
      slots 3
    end

    args do
      mode :parallel
    end
  end
EOT

dsl_bad = <<EOT
  mid_point 1600

  upper_task do
    nodes do
      instance "xlarge"
      count 15
      slots 3
    end

    args do
      mode :parallel
    end
  end

  lower_task do
    nodes do
      instance "medium"
      count 30
      slots 6
    end
  end

  args do
    mode :parallel
  end
EOT

describe ::Dsl::Builders::BalancedNodesBuilder do

  before do
    @balanced_nodes_builder = ::Dsl::Builders::BalancedNodesBuilder.new
  end

  describe "when a valid block is evaluated" do

    it "should return a Model::BalancedNodes" do
      @balanced_nodes_builder.eval_block { eval dsl_full }
      assert_equal ::Dsl::Model::BalancedNodes, @balanced_nodes_builder.model.class
    end

    it "should generate the correct model" do
      @balanced_nodes_builder.eval_block { eval dsl_full }

      dsl_full_expected_model = ::Dsl::Model::BalancedNodes.new(
        1600,
        ::Dsl::Model::DslBuildSet.new(
          "uppertask",
          Nodes.new(CloudTools::Config.instances['xlarge'], 15, 3, [], {}),
          {:* => {:modes=>[:parallel]}}
        ),
        ::Dsl::Model::DslBuildSet.new(
          "lowertask",
          Nodes.new(CloudTools::Config.instances['medium'], 30, 6, [], {}),
          {}
        )
      )

      assert_equal dsl_full_expected_model, @balanced_nodes_builder.model
    end
  end

  describe "when no block is evaluated" do

    it "should return an empty Model::BalancedNodes" do
      assert_equal ::Dsl::Model::BalancedNodes, @balanced_nodes_builder.model.class
      assert_equal nil, @balanced_nodes_builder.model.midpoint
      assert_equal nil, @balanced_nodes_builder.model.uppertask
      assert_equal nil, @balanced_nodes_builder.model.lowertask
    end
  end

  describe "when a block that lacks one task parameterer is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @balanced_nodes_builder.eval_block { eval dsl_lacks_one_task }
      end
    end
  end

  describe "when a block that lacks required midpoint parameter is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @balanced_nodes_builder.eval_block { eval dsl_lacks_midpoint }
      end
    end
  end

  describe "when a invalid block is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @balanced_nodes_builder.eval_block { eval dsl_bad }
      end
    end
  end

  describe "when a empty block is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @balanced_nodes_builder.eval_block { eval '' }
      end
    end
  end
end
