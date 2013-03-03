module Hdo
  module WebhookDeployer
    class Deploy
      attr_reader :file, :time, :short_sha, :sha, :user, :repo, :branch

      def initialize(path)
        @file = path.gsub(WebhookDeployer.logdir.to_s, '')
        _ ,@user, @repo, @branch, date, time, log_file = @file.split("/")

        @time = Time.parse("#{date} #{time.scan(/\d{2}/).join(':')}")
        @sha  = File.basename(log_file, '.log')
      end

      def short_sha
        sha[0,7]
      end

      def url
        "https://github.com/#{user}/#{repo}/commit/#{sha}"
      end
    end
  end
end