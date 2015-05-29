#
# Author: David Suárez <david.sephirot@gmail.com>
# Date: Sun, 17 May 2015 22:13:49 +0200
#

require 'pp'
require 'open-uri'
require 'json'

require 'cloud-tools/job-based-logger'
require 'cloud-tools/util/hash'

module CloudTools; module Generators;

EXCLUDED_PKGS = %w{
debian-installer
linux-modules-di-i386-2.6
linux-kernel-di-i386-2.6
linux-modules-di-amd64-2.6
linux-kernel-di-amd64-2.6
openclipart
posixtestsuite
}

SOURCE_REBUILD_URL='https://udd.debian.org/cgi-bin/sources_rebuild.cgi'

class TasksGenerator

  include JobBasedLogger

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
  def from_hash(options)

    options = @@defaults.merge(options)

    log_info "generating tasks: opts => #{options}"

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

  def from_task(tasks, global_opts=nil, mixed_opts=nil)
    options = {}

#     if mixed_opts
#       options = merge_mixed_option idx+1, task_opts, global_opts, mixed_opts
#     else
      options = tasks.merge_adding_arys global_opts
#     end

    from_hash(options)
  end

  def from_buid_set(build_set, global_opts=nil, mixed_opts=nil)
    tasks_json = []

    build_set.tasks.each do |k, task_opts|
      tasks_json += from_task task_opts, global_opts, mixed_opts
    end

    tasks_json
  end

  def from_recipe(recipe, global_opts=nil, mixed_opts=nil)

    products = recipe.cook

    thread = []

    products.each do |p|
      thread << Thread::new(p) do |p|
        tasks_json = from_buid_set p, global_opts, mixed_opts

        write_json tasks_json, "tasks-#{p.name}.json"
      end
    end

    # wait for threads
    thread.each do |th|
      th.join
    end
  end

  def write_json(tasks, filename)
    raise "not writing #{filename}, empty tasks" if tasks.empty?

    log_info "writing tasks file #{filename}"

    File.open(filename,"w") do |f|
      f.write(JSON.pretty_generate(tasks))
    end
  end

protected

  @esttimes = nil

  def estimated_times
    return @esttimes if @esttimes

    times_file = File.join($config_dir, 'buildtime.list')

    @esttimes = Hash[
      File::readlines(times_file)
        .map { |l| l.split }
        .map { |e| [ e[0], e[1].to_i ] }
    ]
  end

end

end; end