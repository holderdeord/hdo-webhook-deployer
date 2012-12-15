module Hdo
  module WebhookDeployer
    class Build

      def initialize(data)
        @data = data
      end

      def passed?
        @data['status'] == 0
      end

      def short_name
        @data.fetch('repository').values_at('owner_name', 'name').join('/')
      end

      def branch
        @data.fetch('branch')
      end

      def commit
        @data.fetch('commit')
      end

      def log_file
        date, time = Time.now.strftime('%Y-%m-%d %H%M%S').split(" ")
        WebhookDeployer.logdir.join("#{short_name}/#{branch}/#{date}/#{time}/#{commit}.log")
      end

    end
  end
end