module Hdo
  module WebhookDeployer
    class Deployer
      include Celluloid

      def initialize(config, commit)
        @commit    = commit
        @timeout   = config.fetch('timeout', 60)
        @directory = File.expand_path(config.fetch('directory'))
        @env = config['environment']

        logfile = config.fetch('logfile')
        logfile.dirname.mkpath

        @log = File.open(logfile, 'a')
        @log.sync = true

        @command = Array(config.fetch('command'))
      end

      def execute
        update
        deploy
      rescue => ex
        log "error: #{ex.message}"
      ensure
        log 'all done'
        @log.close
      end

      def update
        run %w(git pull origin master)
        run %W(git checkout -f #{@commit})
      end

      def deploy
        run(@command)
      end

      def run(command)
        log "running #{command.inspect}"

        process     = ChildProcess.build(*command)
        process.cwd = @directory

        if @env
          process.environment.merge!(@env)
        end

        process.io.stdout = @log
        process.io.stderr = @log

        begin
          process.start
          process.poll_for_exit @timeout
        rescue ChildProcess::TimeoutError => ex
          log ex.message
          process.stop
        end

        if process.exit_code != 0
          raise "command failed with code #{process.exit_code}: #{command.inspect}"
        end
      end

      def log(msg)
        unless @log.closed?
          @log.puts "[#{Time.now}: #{@directory}] - #{msg}"
        end
      end

    end
  end
end

