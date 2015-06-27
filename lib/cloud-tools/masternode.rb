#
# Author: David Suárez <david.sephirot@gmail.com>
# Date: Sun, 07 Sep 2014 17:26:37 +0200
#

require 'net/ssh'
require 'net/scp'

require 'cloud-tools/job-based-logger'

module CloudTools

class MasterNode
  
  include JobBasedLogger
  
  def initialize()
    @host = CloudTools::Config.masternode[:host]
    @user = CloudTools::Config.masternode[:"ssh-user"]
    @scripts_dir = CloudTools::Config.masternode[:"work-dir"]
    @ruby_interpreter = CloudTools::Config.masternode[:"ruby-interpreter"]
    
    @scp = nil
    @ssh = nil
  end
  
  def get_scp_connection()
    ssh = get_ssh_connection()
    @scp = ssh.scp
    @scp
  end

  def get_ssh_connection()
    @ssh = Net::SSH.start(@host, @user) if not @ssh
    @ssh
  end
  
  def clear_connections()
    @ssh.close if @ssh
    @ssh = nil
    @scp = nil
  end

  def upload_file(file)
    log_info "uploading #{file} to #{@host}:#{@scripts_dir}"
    
    scp = get_scp_connection()

    # TODO: handle timeouts; retry again ?
    scp.upload!(file, @scripts_dir)
  end

  def launch_rebuild(id, tasks_file, nodes_file, slots, log_path, out_dir)
    cmd = "cd #{@scripts_dir} && screen -d -m -S #{id} #{@ruby_interpreter} masternode " +
          "-t #{@scripts_dir}/#{tasks_file} -n #{@scripts_dir}/#{nodes_file} " +
          "-s #{slots} -o #{log_path} -d #{out_dir}"
    
    log_info "launching rebuild on masternode, cmd: \"#{cmd}\""

    cmd_ret = exec_remote_cmd(cmd)

    raise "launching rebuild has failed, cmd: \"#{cmd}\", std: \"#{cmd_ret[0]}\"" if cmd_ret[1] != 0
  end

  #
  # wait for instances to complete booting and updating of chroots
  #
  def wait_for_instances_to_boot(nodes_file, timeout = 15)

    test_cmd = "clush -S -bw $(nodeset -f < #{@scripts_dir}/#{nodes_file} ) 'true'"
    wait_cmd = "clush -S -bw $(nodeset -f < #{@scripts_dir}/#{nodes_file} ) 'ps aux | grep update' " +
               "| egrep -c 'sbuild-update|Connection refused|Connection timed out|exited with exit code'"

    test_proc = Proc.new {
      cmd_ret = exec_remote_cmd(test_cmd)
      next cmd_ret[1] == 0
    }
    
    update_proc = Proc.new {
      cmd_ret = exec_remote_cmd(wait_cmd)
      next cmd_ret[1] == 1 && cmd_ret[0].chomp == "0"
    }
    
    wait_procs = [
      [test_proc,   "waiting for instances to be ready (booting)"],
      [update_proc, "waiting for instances to be ready (updating chroots)"]
    ]
    
    # grab current time
    start_time = Time.new

    # wait no more than 'timeout' minutes
    stop_time = Time.new + (60 * timeout)

    wait_procs.each do |p|
      proc = p[0]
      wait_msg = p[1]

      log_info wait_msg
    
      while true
        cmd_ret = proc.call
        break if cmd_ret

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
        log_info "#{wait_msg}, elapsed: #{elapsed}s"
      end
    end

    log_info "instances ready"
  end

  def exec_remote_cmd(cmd)
  
    std = ""
    exit_code = nil
    exit_signal = nil

    ssh = get_ssh_connection()

    ssh.open_channel do |channel|
      channel.exec(cmd) do |ch, success|
        
        raise "ssh exec: couldn't execute command #{cmd}" unless success

        channel.on_request("exit-status") do |ch, data|
          exit_code = data.read_long
        end

        channel.on_request("exit-signal") do |ch, data|
          exit_signal = data.read_long
        end

        channel.on_data do |ch, data|
          std += data
        end

        channel.on_extended_data do |ch, type, data|
          std += data
        end
      end
    end

    ssh.loop
    
    return [std, exit_code, exit_signal]
  end

end

end
