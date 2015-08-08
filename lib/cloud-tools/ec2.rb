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

  def from_recipe(recipe)

    products = recipe.cook

    thread = []

    products.each do |p|
      thread << Thread::new(p) do |p|
        request_spot_instances(p.nodes, "nodes-#{p.name}")
      end
    end

    # wait for threads
    thread.each do |th|
      th.join
    end
  end

  def request_spot_instances(nodes, filename)

    log_info "requesting #{nodes.count} spot instance(s) of type #{nodes.instance.type}"

    options = create_spot_request_options(nodes)

    log_info "request options: #{options}"

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

    begin
      tags = Config.defaults[:tags] || {}
      tags = tags.merge nodes[:tags] if nodes[:tags]

      tags.each do |k, v|
        log_info "adding tag #{k}=#{v}"
        tag_instances instances, k, v
      end
    rescue AWS::EC2::Errors::UnauthorizedOperation => ex
      log_error "not authorized to tag instances"
    end

    # write internal ip's
    File.open(filename, 'w') do |file|
      instances.each do |i|
      file.puts i.private_ip_address
      end
    end

    log_info "nodes of type #{nodes.instance.type} written to #{filename}"

    return instances
  end

  def create_spot_request_options(nodes)

    launch_specification = {
      :image_id => Config.defaults[:region].ami,
      :instance_type => nodes.instance.type
    }

    # node level VPC has preference
    subnet_id = Config.defaults[:'vpc-subnet-id']
    subnet_id = nodes[:'vpc-subnet-id'] if nodes[:'vpc-subnet-id']

    #
    # If a VPC (subnet) is specified, AWS wants only the id's of vpc security groups.
    # If not, use non-VPC security groups by name.
    #
    if subnet_id
      security_groups_ids = Config.defaults[:'vpc-securitygroups-ids'] || []
      security_groups_ids += nodes[:'vpc-securitygroups-ids'] if nodes['vpc-securitygroups-ids']

      launch_specification[:security_group_ids] = security_groups_ids if security_groups_ids.any?
      launch_specification[:subnet_id] = subnet_id if subnet_id

    else
      security_groups = Config.defaults[:securitygroups] || []
      security_groups += nodes[:'securitygroups'] if nodes[:securitygroups]

      launch_specification[:security_groups] = security_groups if security_groups.any?
    end

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

  #
  # needs 'ec2:CreateTags'
  #
  def tag_instances(instances, name, value)
    instances.each do |instance|
        instance.tag(name, value: value)
    end
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
