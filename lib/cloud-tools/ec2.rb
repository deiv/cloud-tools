#
# Author: David Suárez <david.sephirot@gmail.com>
# Date: Sat, 04 Jan 2014 15:01:40 +0100
#

require 'aws-sdk'

require 'cloud-tools/job-based-logger'

module CloudTools

class Ec2

  include JobBasedLogger

  @ec2 = nil
  @logger = nil

  def initialize
    AWS.config(
      :access_key_id => Config.defaults[:credentials].id,
      :secret_access_key => Config.defaults[:credentials].secret,
      :region => Config.defaults[:region].name #,
      #:logger => Logger.new($stdout),
      #:log_level => :info
      #:max_retries => 2
    )

    @ec2 = AWS::EC2.new
  end
  
  def request_set(set)
    if set.is_a?(BalancedSet)
      thread = []
      instances = []
      tasks=[set.uppertask, set.lowertask]

      tasks.each do |t|
        thread << Thread::new(t) do |task|
          Thread::abort_on_exception = true

          instances << request_spot_instances(task.nodes, "nodes-#{task.name}")
        end
      end

      # wait for threads
      thread.each do |th|
        th.join
      end

      return instances

    elsif set.is_a?(MixedSet)
      return [request_spot_instances(set.nodes, "nodes-#{set.name}")]

    elsif set.is_a?(Nodes)
      return [request_spot_instances(set, "nodes-#{set.instance.name}")]

    else
      return nil
    end
  end

  def request_spot_instances(nodes, filename)

    log_info "requesting #{nodes.count} spot instance(s) of type #{nodes.instance.type}"

    options = create_spot_request_options(nodes)

    # request instances
    response = @ec2.client.request_spot_instances(options)

    raise "bad response requesting spot instance(s)" if not response.successful?

    requests = []

    # get request id's
    response[:spot_instance_request_set].each do |i|
      requests << i[:spot_instance_request_id]
    end

    log_info "reservation ids of #{nodes.instance.type} spot requests: #{requests}"

    instances = wait_for_instances(nodes.instance.type, requests, 15)

    log_info "nodes of type #{nodes.instance.type} written to #{filename}"

    # write internal ip's
    File.open(filename, 'w') do |file|
      instances.each do |i|
      file.puts i.private_ip_address
      end
    end

    return instances
  end

  def create_spot_request_options(nodes)

    security_groups = Config.defaults[:securitygroups] || []
    security_groups += nodes[:'securitygroups'] if nodes[:'securitygroups']

    launch_specification = {
      :image_id => Config.defaults[:region].ami,
      :instance_type => nodes.instance.type
    }

    launch_specification[:security_groups] = security_groups if security_groups.any?

    options = {
      :spot_price => nodes.instance.price.to_s,
      :instance_count => nodes.count.to_i,
      :launch_specification => launch_specification
    }
  end

  #
  # wait for instances to appear
  #
  def wait_for_instances(type, request_ids, timeout = 15)

    # grab current time
    start_time = Time.new

    # wait no more than 'timeout' minutes
    stop_time = Time.new + (60 * timeout)

    wait_msg = "waiting for #{request_ids.count} instance(s) of type #{type} to appear"

    log_info wait_msg

    instances = nil

    while true

      instances = @ec2.instances
        .filter("instance-state-name", "running")
        .filter("instance-lifecycle", "spot")
        .filter("spot-instance-request-id", request_ids)

      break if instances.count == request_ids.count

      # check for timeout
      now = Time.new
      if now > stop_time then
        raise "error: timeout while #{wait_msg}: you must check the instances by hand"
      end

      # sleep one minute
      sleep 60

      # print status
      now = Time.new
      elapsed = (now - start_time).round(0)
      log_info "#{wait_msg}, elapsed: #{elapsed}s, count: #{instances.count}"

    end

    return instances
  end

  def filter(type)
    instances = @ec2.instances
      .filter("instance-state-name", "running")
      .filter("instance-lifecycle", "spot")
      .filter("instance-type", type)
  end

#   def write_instances_ip(instances)
#   # write internal ip's
#   instances.each do |nodes|
#     filename = "nodes.#{nodes.instance.type}"
#
#     puts "nodes of type #{nodes.instance.type} written to #{filename}"
#
#     File.open(filename, 'w') do |file|
#     nodes.each do |i|
#       file.puts i.private_ip_address
#     end
#     end
#   end
#   end

end

end
