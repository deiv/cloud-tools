
require 'spec_helper'

require 'cloud-tools/dsl/exceptions'
require 'cloud-tools/dsl/builders/build_set'

dsl_full = <<EOT
  nodes do
    instance "xlarge"
    count 15
    slots 3
    tag "Tag1Name", "Tag1Value"
    tag "Tag2Name", "Tag2Value"
    vpc_subnet_id "subnet-id123"
    vpc_securitygroup_id "sg-1234567890"
    vpc_securitygroup_id "sg-0987654321"
    securitygroup "qwerty"
    securitygroup "ytrewq"
  end

  task "test" do
    no_arch_all
    mode :binary_only
  end

  task "reference" do
    no_arch_all
    mode :binary_only
    log_id "normal"
  end
EOT

dsl_full_balanced = <<EOT
  balance_nodes do
    mid_point 1600

    upper_task do
      nodes do
        instance "xlarge"
        count 15
        slots 3
        tag "Tag1Name", "Tag1Value"
        tag "Tag2Name", "Tag2Value"
        vpc_subnet_id "subnet-id123"
        vpc_securitygroup_id "sg-1234567890"
        vpc_securitygroup_id "sg-0987654321"
        securitygroup "qwerty"
        securitygroup "ytrewq"
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
  end

  task "test" do
    no_arch_all
    mode :binary_only
  end

  task "reference" do
    no_arch_all
    mode :binary_only
    log_id "normal"
  end
EOT

dsl_lacks_nodes = <<EOT
  task "test" do
    no_arch_all
    mode :binary_only
  end

  task "reference" do
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

  tska "test" do
    no_arch_all
    mode :binary_only
  end

  task "reference" do
    no_arch_all
    mode :binary_only
    log_id "normal"
  end
EOT

dsl_rewrite = <<EOT
  balance_nodes do
    mid_point 1500

    upper_task do
      nodes do
        instance "medium"
        count 10
        slots 1
      end

      args do
        mode :parallel
      end
    end

    lower_task do
      nodes do
        instance "mlarge"
        count 60
        slots 2
      end
    end
  end

  task "test" do
    mode "clang"
    log_id "clang"
  end
EOT

describe ::Dsl::Builders::BuildSetBuilder do

  before do
    @build_set_builder = ::Dsl::Builders::BuildSetBuilder.new
  end

  describe "when a valid block (simple) is evaluated" do

    it "should return a Model::DslBuildSet" do
      @build_set_builder.eval_block { eval dsl_full }
      assert_equal ::Dsl::Model::DslBuildSet, @build_set_builder.model.class
    end

    it "should generate the correct model" do
      dsl_full_expected_model = ::Dsl::Model::DslBuildSet.new(
        '',
        Nodes.new(
          CloudTools::Config.instances['xlarge'],
          15,
          3,
          ["qwerty", "ytrewq"],
          { "Tag1Name" => "Tag1Value", "Tag2Name" => "Tag2Value"},
          "subnet-id123",
          ["sg-1234567890", "sg-0987654321"]
        ),
        { "test"=>{:no_arch_all=>true, :modes=>[:binary_only]},
          "reference"=>{:no_arch_all=>true, :modes=>[:binary_only], :log_id=>"normal"} }
      )

      @build_set_builder.eval_block { eval dsl_full }
      assert_equal dsl_full_expected_model, @build_set_builder.model
    end
  end


  describe "when a valid block (balanced) is evaluated" do

    it "should return a Model::DslBuildSet" do
      @build_set_builder.eval_block { eval dsl_full_balanced }
      assert_equal ::Dsl::Model::DslBuildSet, @build_set_builder.model.class
    end

    it "should generate the correct model" do
      dsl_full_expected_model_balanced = ::Dsl::Model::DslBuildSet.new(
        '',
        ::Dsl::Model::BalancedNodes.new(
          1600,
          ::Dsl::Model::DslBuildSet.new(
            "uppertask",
            Nodes.new(
              CloudTools::Config.instances['xlarge'],
              15,
              3,
              ["qwerty", "ytrewq"],
              { "Tag1Name" => "Tag1Value", "Tag2Name" => "Tag2Value"},
              "subnet-id123",
              ["sg-1234567890", "sg-0987654321"]
            ),
            {:* => {:modes=>[:parallel]}}
          ),
          ::Dsl::Model::DslBuildSet.new(
            "lowertask",
            Nodes.new(CloudTools::Config.instances['medium'], 30, 6, [], {}, nil, []),
            {}
          )
       ),
       { "test"=>{:no_arch_all=>true, :modes=>[:binary_only]},
         "reference"=>{:no_arch_all=>true, :modes=>[:binary_only], :log_id=>"normal"} }
      )

      @build_set_builder.eval_block { eval dsl_full_balanced }
      assert_equal dsl_full_expected_model_balanced, @build_set_builder.model
    end
  end

  describe "when no block is evaluated" do

    it "should return an empty Model::DslBuildSet" do
      assert_equal ::Dsl::Model::DslBuildSet, @build_set_builder.model.class
      assert_equal "", @build_set_builder.model.name
      assert_equal nil, @build_set_builder.model.nodes
      assert_equal Hash.new, @build_set_builder.model.args
    end
  end

  describe "when a block that lacks required nodes parameter is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @build_set_builder.eval_block { eval dsl_lacks_nodes }
      end
    end
  end

  describe "when a block have both of some alternatives parameters" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @build_set_builder.eval_block { eval "#{dsl_full}\n#{dsl_full_balanced}" }
      end
    end
  end

  describe "when a invalid block is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @build_set_builder.eval_block { eval dsl_bad }
      end
    end
  end

  describe "when a empty block is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @build_set_builder.eval_block { eval '' }
      end
    end
  end

  describe "when an extended model is inherited" do

    it "should inherit all the parent model" do
      parent_builder = ::Dsl::Builders::BuildSetBuilder.new
      parent_builder.eval_block { eval dsl_full_balanced }
      @build_set_builder.inherit parent_builder

      assert_equal parent_builder.model, @build_set_builder.model
    end

    it "should not inherit the parent name" do
      parent_builder = ::Dsl::Builders::BuildSetBuilder.new "thename"
      parent_builder.eval_block { eval dsl_full_balanced }
      @build_set_builder.inherit parent_builder

      refute_equal parent_builder.model.name, @build_set_builder.model.name
    end

    it "should rewrite the inherited parameters if present" do
      parent_builder = ::Dsl::Builders::BuildSetBuilder.new
      parent_builder.eval_block { eval dsl_full_balanced }
      @build_set_builder.inherit parent_builder
      @build_set_builder.eval_block { eval dsl_rewrite }

      refute_equal parent_builder.model.nodes, @build_set_builder.model.nodes
      refute_equal parent_builder.model.args, @build_set_builder.model.args
    end
  end
end
