#
# Author: David Suárez <david.sephirot@gmail.com>
# Date: Sat, 04 Jan 2014 15:01:40 +0100
#

require 'pp'
require 'open-uri'
require 'json'

module CloudTools

EXCLUDED_PKGS = %w{
debian-installer
linux-modules-di-i386-2.6
linux-kernel-di-i386-2.6
linux-modules-di-amd64-2.6
linux-kernel-di-amd64-2.6
openclipart
posixtestsuite
}

SOURCE_REBUILD_URL='http://udd.debian.org/cgi-bin/sources_rebuild.cgi'

class TasksGenerator
  
  @srcs_url
  @srcs

  def initialize(srcs_url=SOURCE_REBUILD_URL)
    @srcs_url = srcs_url
    srcs
    estimated_times
  end

  def srcs
    return @srcs if @srcs

    @srcs = open(@srcs_url).readlines.
      select { |l| l !~ /excluded-by-P-A-S/ }.
      map { |l| l.split }.
      reject { |e| EXCLUDED_PKGS.include?(e[0]) }
  end
  
  @@defaults = {
    :chroot => "unstable",
    :noall => false,
    :log_id => nil,
    :time_upper => nil,
    :time_lower => nil,
    :pkgs_include => nil,
    :pkgs_exclude => nil,
    :modes => []
  }

  #
  # Generates the tasks json from options hash.
  #
  def generate(options)

    options = @@defaults.merge(options)
    
    puts "generate: opts => #{options}"
    
    esttime = estimated_times

    pkgs = srcs.reject { |e| options[:noall] and e[2] == 'all' }

    tasks = []

    pkgs.each do |e|
      t = {}
      t['source'] = e[0]
      t['version'] = e[1]
      t['architecture'] = e[2]
      t['chroot'] = options[:chroot]
      t['esttime'] = esttime[e[0]] || nil
      
      logversion = t['version'].gsub(/^[0-9]+:/,'')
      if options[:log_id]
        t['logfile'] = "/tmp/#{t['source']}_#{logversion}_#{t['chroot']}_#{options[:log_id]}.log"
      else
        t['logfile'] = "/tmp/#{t['source']}_#{logversion}_#{t['chroot']}.log"
      end
      
      if options[:time_upper] and not t['esttime'].nil?
        next if t['esttime'] >= options[:time_upper]
      end
      if options[:time_lower]
        next if t['esttime'].nil? or t['esttime'] < options[:time_lower]
      end
      
      next if options[:pkgs_include] and not options[:pkgs_include].include?(t['source'])
      next if options[:pkgs_exclude] and options[:pkgs_exclude].include?(t['source'])
      
      t['modes'] = options[:modes]
      
      tasks << t
    end

    return tasks
  end

  #
  # Generates the tasks json from a task struct.
  #
  def from_task(task, tasks_opts=nil, mixed_opts=nil)

    tasks_opts = {} if not tasks_opts

    if task.is_a?(MixedSet)
      tasks = []

      task.tasks.each_index do |idx|
        options = {}
        set_opts = parse_options(task.tasks[idx].args)

        if mixed_opts
          options = merge_mixed_option idx+1, set_opts, tasks_opts, mixed_opts
        else
          options = merge_options set_opts, tasks_opts
        end

        tasks += generate(options)
      end

      return tasks

    else
      raise "can't handle mixed set options, the task is not a mixed set" if not mixed_opts.empty?

      options = merge_options parse_options(task.args), tasks_opts
      return generate(options)
    end
  end

  #
  # Writes all the json tasks files need by a set.
  #
  def from_buildset(set, tasks_opts=nil, mixed_opts=nil)
    
    if set.is_a?(BalancedSet)
      thread = []
      tasks=[set.uppertask, set.lowertask]

      tasks.each do |t|
        thread << Thread::new(t, t==set.uppertask) do |task, upper|

          Thread::abort_on_exception = true
          
          if upper
            set_opts = { :time_upper => set.midpoint }
          else
            set_opts = { :time_lower => set.midpoint }
          end

          set_opts = set_opts.merge(tasks_opts) if tasks_opts

          tasks = from_task(task, set_opts, mixed_opts)
          # task.nodes.instance.type
          write_json tasks, "tasks-#{task.name}.json"
        end
      end
      
      # wait for threads
      thread.each do |th|
        th.join
      end

      return tasks

    elsif set.is_a?(MixedSet)
      tasks = from_task(set, tasks_opts, mixed_opts)

      write_json tasks, "tasks-#{set.name}.json"

    else
      raise "the argument passed is not a set"
    end
  end

  def write_json(tasks, filename)
    if tasks.empty?
      puts "warn: not writing #{filename}, empty tasks"
    end

    puts "writing tasks file #{filename}"

    File.open(filename,"w") do |f|
      f.write(JSON.pretty_generate(tasks))
    end
  end

  def to_json(tasks)
    return JSON::pretty_generate(tasks)
  end

protected

  @esttimes = nil

  def estimated_times
    return @esttimes if @esttimes

    times_file = File.join(File.dirname($config_dir), 'buildtime.list')
    
    @esttimes = Hash[
      File::readlines(times_file)
        .map { |l| l.split }
        .map { |e| [ e[0], e[1].to_i ] }
    ]
  end

  def parse_options(args)
    options = {}
    
    return options unless args

    opts_parser = OptionParser::new do |opts|
      opts.on("-m", "--mode MODE") { |m|
        options[:modes] = [] unless options[:modes]
        options[:modes] << m 
      }
      opts.on("", "--no-arch-all")       { options[:noall] = true }
      opts.on("-l", "--time-lower TIME") { |t| options[:time_lower] = t.to_i }
      opts.on("-u", "--time-upper TIME") { |t| options[:time_upper] = t.to_i }
      opts.on("-c", "--chroot CHROOT")   { |t| options[:chroot] = t }
      opts.on("-i", "--id TEXT")         { |t| options[:log_id] = t }
      opts.on("", "--include FILE")      { |t| options[:pkgs_include] = IO::read(t).split }
      opts.on("", "--exclude FILE")      { |t| options[:pkgs_exclude] = IO::read(t).split }
    end

    if args.is_a? String
      opts_parser.parse!(args.split)
    elsif args.is_a? Array
      opts_parser.parse!(args)
    else
      return nil
    end

    options
  end

  #
  # Merge options, taking into account that ":modes" is an array.
  # Therefore we are suming it instead of rewriting.
  #
  def merge_options(opts1, opts2)
    opts1.merge(opts2) do |key, old, new|
      if key == :modes
        old + new
      else
        new
      end
    end
  end

  #
  # Merge the set options against the the "commandline passed" options.
  #
  # This takes into account that "mixed sets" options, can be aplied to
  # some specific set.
  #
  def merge_mixed_option(mix_id, set_opts, task_options, mixed_opts)

    options = merge_options set_opts.dup, task_options

    mixed_opts.each do |k, v|
      key_str = k.to_s

      next if key_str[-1] != mix_id.to_s

      last_idx = key_str.rindex "_"
      key = key_str[0..last_idx-1].to_sym

      options = merge_options options, { key => mixed_opts[k] } if key
    end

    return options
  end
end

end
