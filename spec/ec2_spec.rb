
require 'spec_helper'

require 'cloud-tools/ec2'
require 'cloud-tools/config'

describe CloudTools::Ec2 do

  before do
    @ec2 = CloudTools::Ec2.new
  end

  describe "when creating spot request options from nodes" do

    it "should return the correct options" do
      nodes = Nodes.new(
        Instance.new("xlarge", "m2.xlarge", 0.5),
        15,
        3,
        ["sg1", "sg2"],
        { "Tag1Name" => "Tag1Value", "Tag2Name" => "Tag2Value" },
        nil,
        [],
        nil
      )

      expected_options = {
        :spot_price => "0.5",
        :instance_count => 15,
        :launch_specification => {
          :image_id => "ami-test-default-sa-east",
          :instance_type => "m2.xlarge",
          :security_group_ids => ["sg-45876738"],
          :subnet_id => "subnet-test"
        }
      }

      options = @ec2.create_spot_request_options nodes

      assert_equal expected_options, options
    end

    it "should return the correct options when the instance has an ami" do
      nodes = Nodes.new(
        Instance.new("xlarge", "m2.xlarge", 0.5, "ami-test-1"),
        15,
        3,
        ["sg1", "sg2"],
        { "Tag1Name" => "Tag1Value", "Tag2Name" => "Tag2Value" },
        nil,
        [],
        nil
      )

      expected_options = {
        :spot_price => "0.5",
        :instance_count => 15,
        :launch_specification => {
          :image_id => "ami-test-1-sa-east",
          :instance_type => "m2.xlarge",
          :security_group_ids => ["sg-45876738"],
          :subnet_id => "subnet-test"
        }
      }

      options = @ec2.create_spot_request_options nodes

      assert_equal expected_options, options
    end

    it "should return the correct options when both, the instance and nodes have an ami" do
      nodes = Nodes.new(
        Instance.new("xlarge", "m2.xlarge", 0.5, "ami-test-1"),
        15,
        3,
        ["sg1", "sg2"],
        { "Tag1Name" => "Tag1Value", "Tag2Name" => "Tag2Value" },
        nil,
        [],
        "ami-test-2"
      )

      expected_options = {
        :spot_price => "0.5",
        :instance_count => 15,
        :launch_specification => {
          :image_id => "ami-test-2-sa-east",
          :instance_type => "m2.xlarge",
          :security_group_ids => ["sg-45876738"],
          :subnet_id => "subnet-test"
        }
      }

      options = @ec2.create_spot_request_options nodes

      assert_equal expected_options, options
    end

    it "should add instance security groups when a VPC is not provided" do

      saved_vpc = CloudTools::Config.defaults[:'vpc-subnet-id']
      CloudTools::Config.defaults[:'vpc-subnet-id'] = nil

      nodes = Nodes.new(
        Instance.new("xlarge", "m2.xlarge", 0.5, "ami-test-1"),
        15,
        3,
        ["sg1", "sg2"],
        { "Tag1Name" => "Tag1Value", "Tag2Name" => "Tag2Value" },
        nil,
        [],
        "ami-test-2"
      )

      expected_options = {
        :spot_price => "0.5",
        :instance_count => 15,
        :launch_specification => {
          :image_id => "ami-test-2-sa-east",
          :instance_type => "m2.xlarge",
          :security_groups => ["test-sg", "no-network-access", "sg1", "sg2"]
        }
      }

      options = @ec2.create_spot_request_options nodes

      CloudTools::Config.defaults[:'vpc-subnet-id'] = saved_vpc

      assert_equal expected_options, options
    end
  end

  describe "when getting tags from nodes" do

    it "should return the correct ones" do
      nodes = Nodes.new(
        Instance.new("xlarge", "m2.xlarge", 0.5),
        15,
        3,
        ["sg1", "sg2"],
        { "Tag1Name" => "Tag1Value", "Tag2Name" => "Tag2Value" },
        nil,
        [],
        nil
      )

      expected_tags = {"Team"=>"test", "Tag1Name"=>"Tag1Value", "Tag2Name"=>"Tag2Value"}

      tags = @ec2.get_nodes_tags nodes

      assert_equal expected_tags, tags
    end

    it "should return the correct ones when the nodes doesn't have" do
      nodes = Nodes.new(
        Instance.new("xlarge", "m2.xlarge", 0.5),
        15,
        3,
        ["sg1", "sg2"],
        {},
        nil,
        [],
        nil
      )

      expected_tags = {"Team"=>"test"}

      tags = @ec2.get_nodes_tags nodes

      assert_equal expected_tags, tags
    end
  end

end
