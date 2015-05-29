
require 'cloud-tools/dsl/exceptions'

module Dsl
  module DslSyntax

    def method_missing(sym, *args, &block)
      raise Dsl::InvalidSyntaxError.new(sym)
    end

    def eval_block(&block)
      self.instance_eval(&block)
      validate_model if self.respond_to? :validate_model
    end

    def validate_presence(obj, msg)
      raise Dsl::InvalidSyntaxError.new(msg) if not obj
    end
  end
end
