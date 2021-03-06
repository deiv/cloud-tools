
require 'cloud-tools/dsl/model'
require 'cloud-tools/dsl/builders/args'
require 'cloud-tools/dsl/builders/nodes'
require 'cloud-tools/dsl/dsl_syntax'
require 'cloud-tools/util/hash'

module Dsl; module Builders;

  class BalancedTaskBuilder
    include DslSyntax

    attr_reader :model

    def initialize(name = '')
      @model = Model::DslBuildSet.new
      @model.name = name
      @model.args = {}
    end

    def nodes(&block)
      raise Dsl::InvalidSyntaxError.new('Should have only one nodes definition') if @model.nodes

      parser = NodesBuilder.new()
      parser.eval_block(&block)
      @model.nodes = parser.model
    end

    def args(&block)
      parser = ArgsBuilder.new()
      parser.eval_block(&block)

      @model.args[:*] = parser.model
    end

    def validate_model
      validate_presence @model.name, "should have a name"
      validate_presence @model.nodes, "should have a nodes definition"
    end
  end

end; end;
