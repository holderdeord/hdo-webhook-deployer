module Hdo
  module WebhookDeployer
    class Build

      def initialize(data)
        @data = data
      end

      def passed?
        @data['status'] == 'passed'
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
        WebhookDeployer.logdir.join("#{short_name}/#{branch}/#{commit}-#{Time.now.strftime('%Y-%m-%d-%H%M%S')}.log")
      end

    end
  end
end