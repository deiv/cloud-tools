
require 'spec_helper'

require 'cloud-tools/model'
require 'cloud-tools/dsl/cooker'
require 'cloud-tools/util/hash'

wildcard_args = {
  :inner_hash1 => {
    :key1 => 'value1',
    :key2 => 'value2'
  },
  :inner_hash2 => {
    :key3 => 'value3',
    :key4 => 'value4'
  },
  :* => {
    :wildcard1 => 'wildcard1'
  }
}

normal_args = {
  :inner_hash1 => {
    :key1 => 'value1',
    :key2 => 'value2'
  },
  :inner_hash2 => {
    :key3 => 'value3',
    :key4 => 'value4'
  }
}

describe ::Dsl::BuildSetCooker do

  before do
    @cooker = ::Dsl::BuildSetCooker.new
  end

  describe "when cooking a recipe model with simple Nodes" do
    it "should return the correct model" do
      recipe_model = ::Dsl::Model::DslBuildSet.new(
        "name",
        Nodes.new(
          Instance.new("xlarge", "m2.xlarge", 0.5),
          15,
          3,
          "sg1"
        ),
        normal_args
      )

      products_cooked = [
        BuildSet.new(
          "name",
          Nodes.new(
            Instance.new("xlarge", "m2.xlarge", 0.5),
            15,
            3,
            "sg1"
          ),
          normal_args
        )
      ]

      products = @cooker.cook recipe_model

      assert_equal products_cooked, products
    end
  end

  describe "when cooking a recipe model with a BalancedNodes" do
    it "should return the correct model" do
      recipe_model = ::Dsl::Model::DslBuildSet.new(
        "name",
        ::Dsl::Model::BalancedNodes.new(
          1600,
          ::Dsl::Model::DslBuildSet.new(
            "uppertask",
            Nodes.new(CloudTools::Config.instances['xlarge'], 15, 3, "sg1"),
            {:* => {:wildcard1 => 'wildcard1'}}
          ),
          ::Dsl::Model::DslBuildSet.new(
            "lowertask",
            Nodes.new(CloudTools::Config.instances['medium'], 30, 6, "sg2"),
            {}
          )
        ),
        normal_args
      )

      products_cooked = [
        BuildSet.new(
          "name-uppertask",
          Nodes.new(CloudTools::Config.instances['xlarge'], 15, 3, "sg1"),
          {
            :inner_hash1 => {
              :key1 => "value1",
              :key2 => "value2",
              :wildcard1 => "wildcard1",
              :time_lower => 1600
            },
            :inner_hash2 => {
              :key3 => "value3",
              :key4 => "value4",
              :wildcard1 => "wildcard1",
              :time_lower => 1600
            }
          }
        ),
        BuildSet.new(
          "name-lowertask",
          Nodes.new(CloudTools::Config.instances['medium'], 30, 6, "sg2"),
          {
            :inner_hash1 => {
              :key1 => "value1",
              :key2 => "value2",
              :time_upper => 1600
            },
            :inner_hash2 => {
              :key3 => "value3",
              :key4 => "value4",
              :time_upper => 1600
            }
          }
        )
      ]

      products = @cooker.cook recipe_model

      assert_equal products_cooked, products
    end
  end

  describe "when apply wildcards" do

    it "should not modify the hash if there aren't any" do

      no_wildcard_args = {
        :inner_hash1 => {
          :key1 => 'value1',
          :key2 => 'value2'
        },
        :inner_hash2 => {
          :key3 => 'value3',
          :key4 => 'value4'
        },
      }

      no_expected_args = {
        :inner_hash1 => {
          :key1 => 'value1',
          :key2 => 'value2'
        },
        :inner_hash2 => {
          :key3 => 'value3',
          :key4 => 'value4'
        },
      }

      no_result_args = @cooker.instance_eval { apply_wildcards no_wildcard_args }

      assert_equal no_expected_args, no_result_args
    end

    it "should add them correctly" do

      aplied_wildcard_args = {
        :inner_hash1 => {
          :key1 => 'value1',
          :key2 => 'value2',
          :wildcard1 => 'wildcard1'
        },
        :inner_hash2 => {
          :key3 => 'value3',
          :key4 => 'value4',
          :wildcard1 => 'wildcard1'
        }
      }

      result_args = @cooker.instance_eval { apply_wildcards wildcard_args }
      assert_equal aplied_wildcard_args, result_args
    end

    it "should remove them when applied" do
      result_args = @cooker.instance_eval { apply_wildcards wildcard_args }
      assert_equal nil, result_args[:*]
    end
  end

  describe "when apply balanced args" do

    it "should add upper options correctly" do
      expected_normal_args = {
        :inner_hash1 => {
          :key1 => 'value1',
          :key2 => 'value2',
          :time_lower => 1300
        },
        :inner_hash2 => {
          :key3 => 'value3',
          :key4 => 'value4',
          :time_lower => 1300
        }
      }
      result_args = @cooker.instance_eval { apply_balanced_params normal_args.deep_copy, true, 1300 }
      assert_equal expected_normal_args, result_args
    end

    it "should add lower options correctly" do
      expected_normal_args = {
        :inner_hash1 => {
          :key1 => 'value1',
          :key2 => 'value2',
          :time_upper => 1300
        },
        :inner_hash2 => {
          :key3 => 'value3',
          :key4 => 'value4',
          :time_upper => 1300
        }
      }
      result_args = @cooker.instance_eval { apply_balanced_params normal_args.deep_copy, false, 1300 }
      assert_equal expected_normal_args, result_args
    end
  end
end
