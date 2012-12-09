module Hdo
  module WebhookDeployer
    class Deployer
      include Celluloid

      def initialize(config)
        @timeout   = config.fetch('timeout', 60)
        @directory = File.expand_path(config.fetch('directory'))

        command = Array(config.fetch('command'))
        @process = ChildProcess.build(*command)
        @process.cwd = @directory

        if config.include?('environment')
          @process.environment.merge!(config['environment'])
        end

        logfile = config.fetch('logfile')
        logfile.dirname.mkpath

        @log = File.open(logfile, 'a')
        @log.sync = true
        @process.io.stdout = @log
        @process.io.stderr = @log
      end

      def execute
        log 'deploying'

        @process.start
        @process.poll_for_exit @timeout
      rescue ChildProcess::TimeoutError => ex
        log ex.message
        @process.stop
      ensure
        log 'all done'
        @log.close
      end

      def log(msg)
        unless @log.closed?
          @log.puts "[#{Time.now}: #{@directory}] - #{msg}"
        end
      end

    end
  end
end

