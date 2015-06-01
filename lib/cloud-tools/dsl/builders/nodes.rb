
require 'cloud-tools/dsl/dsl_syntax'

module Dsl; module Builders;

  class NodesBuilder
    include DslSyntax

    attr_reader :model

    def initialize()
      @model = Nodes.new
      @model.securitygroups = []
      @model.tags = {}
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

    def securitygroups(s)
      @model.securitygroups = s
    end

    def tag(k, v)
      @model.tags[k] = v
    end

    def validate_model
      validate_presence @model.instance,"should have an instance type"
      validate_presence @model.count, "should have a nodes count"
      validate_presence @model.slots, "should have a slots count"
    end
  end

end; end;
