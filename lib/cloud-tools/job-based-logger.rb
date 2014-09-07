#
# Author: David Suárez <david.sephirot@gmail.com>
# Date: Sun, 07 Sep 2014 17:26:37 +0200
#

require 'logger'

module CloudTools

  module JobBasedLogger

    def self.create_logger()
      logger = Logger.new($stdout)

      logger.formatter = proc do |severity, datetime, jobname, msg|
        date_str = datetime.strftime("%H:%M:%S")

        if jobname
          "#{date_str} [job #{jobname}]: #{msg}\n"
        else
          "#{date_str}: #{msg}\n"
        end
      end

      return logger
    end

    @@std_logger = self.create_logger

    def log_info(msg)
      if @jobname
        @@std_logger.info(@jobname) { msg }
      else
        @@std_logger.info(msg)
      end
    end
    
    def log_warning(msg)
      if @jobname
        @@std_logger.warn(@jobname) { msg }
      else
        @@std_logger.warn(msg)
      end
    end
    
    def log_error(msg)
      if @jobname
        @@std_logger.error(@jobname) { msg }
      else
        @@std_logger.error(msg)
      end
    end

    def set_log_jobname(jobname)
      @jobname = jobname
    end

    def reset_jobname()
      jobname = nil
    end

  end

end
