module Hdo
  module WebhookDeployer
    class Deployer
      include Celluloid

      def initialize(config, commit)
        @commit    = commit
        @timeout   = config.fetch('timeout', 60)
        @directory = File.expand_path(config.fetch('directory'))
        @env       = {'GIT_COMMIT' => commit}.merge(config['environment'] || {})

        logfile = config.fetch('logfile')
        logfile.dirname.mkpath

        @log = File.open(logfile, 'a')
        @log.sync = true

        @command = Array(config.fetch('command'))
      end

      def execute
        update
        WebhookDeployer.statsd.time('deploy.time') { deploy }
        WebhookDeployer.statsd.increment 'deploy.success'
      rescue => ex
        WebhookDeployer.statsd.increment 'deploy.failure'
        log "error: #{ex.message}"
      ensure
        log 'all done'
        @log.close
      end

      def update
        run %w(git fetch origin)
        run %W(git checkout -f #{@commit})
      end

      def deploy
        command = @command.map do |e|
          e.gsub("%{sha}", @commit.to_s)
        end

        run command
      end

      def run(command)
        log "running #{command.inspect}"

        process     = ChildProcess.build(*command)
        process.cwd = @directory

        process.environment.merge!(@env)

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

