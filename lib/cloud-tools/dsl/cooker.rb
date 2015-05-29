
require 'cloud-tools/config'
require 'cloud-tools/model'
require 'cloud-tools/util/hash'

require 'pry'

module Dsl

  class BuildSetCooker

    def cook(recipe_model)
      products = []

      if recipe_model.nodes.is_a? Model::BalancedNodes
        recipe_model.nodes.each_tasks do |task|
          name = "#{recipe_model.name}-#{task.name}"
          args = task.args.merge_deep_copy recipe_model.args
          args = apply_wildcards args
          args = apply_balanced_params args, task == recipe_model.nodes.uppertask, recipe_model.nodes.midpoint
          products << BuildSet.new(name, task.nodes, args)
        end

      else
        products << BuildSet.new(recipe_model.name, recipe_model.nodes, recipe_model.args)
      end

      products
    end

   private

    def apply_wildcards(args)
      if args.has_key? :*
        wildcard_args = args[:*]
        args.delete(:*)

        args.each do |key, value|
          args[key].merge_adding_arys! wildcard_args
        end
      end

      args
    end

    def apply_balanced_params(args, uppertask, midpoint)
      balanced_args = {}

      if uppertask
        balanced_args[:time_lower] = midpoint
      else
        balanced_args[:time_upper] = midpoint
      end

      args.each do |k, v|
        args[k].merge! balanced_args
      end
    end
  end

end
