module Delayed
  module Web
    class Job::ActiveRecord
      def self.find(*args)
        decorate Delayed::Job.find(*args)
      end

      ORDERING = Arel.sql("CASE WHEN failed_at IS NOT NULL THEN 0 ELSE 1 END, failed_at ASC NULLS LAST, id DESC")

      def self.all
        jobs = Delayed::Job.order(Arel.sql("CASE WHEN failed_at IS NOT NULL THEN 0 ELSE 1 END, failed_at ASC NULLS LAST, id DESC")).limit(1000)
        Enumerator.new do |enumerator|
          jobs.each do |job|
            enumerator.yield decorate(job)
          end
        end
      end

      def self.job_data
        Delayed::Job.group(handler_to_job_name).count.sort_by { |_, v| -v }.to_h
      end

      def self.decorate(job)
        job = StatusDecorator.new job
        job = ActiveRecordDecorator.new job
        job
      end

      def self.by_job_name(job_name = nil)
        scope = Delayed::Job.where(locked_at: nil, locked_by: nil).where("last_error IS NOT NULL OR failed_at IS NOT NULL").select("*, #{handler_to_job_name} as job_name")
        if job_name
          scope = scope.where("#{handler_to_job_name} = ?", job_name)
        end
        jobs = scope.order("id DESC").limit(1000)
        Enumerator.new do |enumerator|
          jobs.each do |job|
            enumerator.yield decorate(job)
          end
        end
      end

      def self.handler_to_job_name
        case Delayed::Job.connection.adapter_name
        when "PostgreSQL"
          "SUBSTRING(delayed_jobs.handler, ':(\\w+){1}\\n')"
        when "MySQL", "Mysql2"
          "SUBSTRING(delayed_jobs.handler, ':(\\w+){1}\\n')"
        else
          raise("Missing Handler function for #{Delayed::Job.connection.adapter_name}")
        end
      end
    end
  end
end
