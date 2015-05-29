
require 'cloud-tools/dsl/model'
require 'cloud-tools/dsl/builders/balanced_task'
require 'cloud-tools/dsl/dsl_syntax'

module Dsl; module Builders;

  class BalancedNodesBuilder
    include DslSyntax

    attr_reader :model

    def initialize
      @model = Model::BalancedNodes.new
    end

    def mid_point(m)
      @model.midpoint = m
    end

    def upper_task(&block)
      @model.uppertask = parse_task "uppertask", &block
    end

    def lower_task(&block)
      @model.lowertask = parse_task "lowertask", &block
    end

    def validate_model
      validate_presence @model.midpoint, "should have a mid_point"
      validate_presence @model.uppertask, "should have an upper_task"
      validate_presence @model.lowertask, "should have an lower_task"
    end

   protected
    def parse_task(name, &block)
      parser = BalancedTaskBuilder.new(name)
      parser.eval_block(&block)
      parser.model
    end
  end

end; end;
