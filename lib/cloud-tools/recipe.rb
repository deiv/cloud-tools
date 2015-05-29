
require 'cloud-tools/dsl/exceptions'
require 'cloud-tools/dsl/builders/build_set'
require 'cloud-tools/dsl/cooker'
require 'cloud-tools/dsl/dsl_syntax'

module CloudTools;

  class Recipe
    include Dsl::DslSyntax

    def initialize(filename)
      @filename = filename
      @builders = {}
      @cookers = {}
      @includes = []
    end

    def self.load(filename)
      recipe = new filename
      recipe.instance_eval File.read(filename), filename
      recipe
    end

    def name
      File.basename(@filename, '.recipe')
    end

    def cook
      products = []

      @builders.each do |key, builder|
        cooker = @cookers[key]
        product = cooker.cook builder.model

        if product.is_a? Array
          products = products + product
        else
          products << product
        end
      end

      products
    end

   protected

    def get_builder(name)
      @builders[name]
    end

   private
    def build_set(name, args = {}, &block)
      builder = Dsl::Builders::BuildSetBuilder.new(name)

      if args[:inherits]
        parent_builder = search_includes(args[:inherits])
        builder.inherit(parent_builder)
      end
      builder.eval_block(&block)

      @builders[name] = builder
      @cookers[name] = Dsl::BuildSetCooker.new
    end

    def include_recipe(name)
      @includes << name
    end

    def search_includes(artifact_name)
      artifact = nil
      @includes.each do |recipe|
        include_recipe = Recipe.load "#{recipe}.recipe"
        artifact = include_recipe.get_builder artifact_name

        break if artifact
      end

      # XXX: fallback to cookbook path ?
      raise "include artifact #{artifact_name} not found" if not artifact

      artifact
    end
  end
end
