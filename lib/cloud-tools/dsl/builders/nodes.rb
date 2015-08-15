
require 'cloud-tools/dsl/dsl_syntax'

module Dsl; module Builders;

  class NodesBuilder
    include DslSyntax

    attr_reader :model

    def initialize()
      @model = Nodes.new
      @model.securitygroups = []
      @model.tags = {}
      @model[:'vpc-securitygroups-ids'] = []
    end

    def instance(i)
      @model.instance = CloudTools::Config.instances[i]
    end

    def count(c)
      @model.count = c
    end

    def slots(s)
      @model.slots = s
    end

    def securitygroup(s)
      @model.securitygroups << s
    end

    def tag(k, v)
      @model.tags[k] = v
    end

    def vpc_subnet_id(id)
      @model[:'vpc-subnet-id'] = id
    end

    def vpc_securitygroup_id(id)
      @model[:'vpc-securitygroups-ids'] << id
    end

    def ami(a)
      @model.ami = a
    end

    def validate_model
      validate_presence @model.instance,"should have an instance type"
      validate_presence @model.count, "should have a nodes count"
      validate_presence @model.slots, "should have a slots count"
    end
  end

end; end;
