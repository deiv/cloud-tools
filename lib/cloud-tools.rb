
require 'cloud-tools/version'
require 'cloud-tools/model.rb'
require 'cloud-tools/config.rb'

module CloudTools

  $config_dir = File.join(ENV['HOME'], ".cloud-tools")

  def self.puts_indented(text, level)
    puts "  " * level + text
  end
  
  def self.pretty_recipe(recipe)
    products = recipe.cook

    puts_indented "- #{recipe.name} recipe produces:", 0

    products.each do |p|
      puts ""
      puts_indented "+ #{p.name} [BuildTask]:", 1
      puts_indented "args:", 2
      p.tasks.each do |k, v|
        puts_indented "#{k} -> \"#{v}\"", 3
      end
      puts_indented "nodes -> #{p.nodes.count} x (#{p.nodes.instance.type} - #{p.nodes.instance.price}$)", 2      
    end

    puts ""
  end

end
