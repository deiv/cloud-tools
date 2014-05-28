
require "cloud-tools/version"
require 'cloud-tools/model.rb'
require 'cloud-tools/config.rb'

module CloudTools
  INSTANCE_TYPES = { :medium => "m1.medium", :large => "m1.large", :xlarge => "m2.xlarge" }
  
  $config_dir = File.join(File.dirname(__FILE__), "../config/instances.yml")
  
  def self.pretty_print_set(set)
	pretty_set set, 0
  end
  
  def self.pretty_set(set, indent_level)
	
	if set.is_a? MixedSet
	  puts_indented "- #{set.name} [MixedSet]:", indent_level
	  
	  set.tasks.each do |t|
	      pretty_task t, 1
	  end
	  puts_indented "nodes -> #{set.nodes.count} x (#{set.nodes.instance.type} - #{set.nodes.instance.price}$)", 1

	else
	  puts_indented "- #{set.name} [BalancedSet] (midpoint: #{set.midpoint}):", indent_level
	  
	  puts_indented "uppertask:", indent_level + 1
	  pretty_task set.uppertask, indent_level + 2
	  
	  puts "\n"
	  
	  puts_indented "lowertask:", indent_level + 1
	  pretty_task set.lowertask, indent_level + 2

	end
	
	puts ""
  end
  
  def self.pretty_task(task, indent_level)

	if task.is_a?(MixedSet)
	  set = task
	  
	  puts_indented "- #{set.name} [MixedSet]:", indent_level
	  
	  set.tasks.each do |t|
		pretty_task t, indent_level + 1
	  end
	  puts_indented "nodes -> #{set.nodes.count} x (#{set.nodes.instance.type} - #{set.nodes.instance.price}$)", indent_level + 1
	  
	elsif task.is_a?(BuildTask)
	  if task.nodes == nil
	    puts_indented "task -> name: #{task.name}, args: \"#{task.args}\"", indent_level

	  else
		puts_indented "task -> name: #{task.name}, args: \"#{task.args}\"", indent_level
		puts_indented "nodes -> #{task.nodes.count} x (#{task.nodes.instance.type} - #{task.nodes.instance.price}$)", indent_level
	  end
	end
  end
  
  def self.puts_indented(text, level)
	puts "  " * level + text
  end

end
