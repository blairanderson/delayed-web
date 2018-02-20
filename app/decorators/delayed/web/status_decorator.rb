module Delayed
  module Web
    class StatusDecorator < SimpleDelegator
      JOB_NAME_REGEX = /:(\w+){1}\n/

      def job_name
        JOB_NAME_REGEX.match(handler)[1]
      end

      def job_args
        handler.split(job_name)[1]
      end

      def status
        case
        when failed_at
          'failed'
        when locked_at && locked_by
          'executing'
        else
          'queued'
        end
      end

      def can_destroy?
        status != 'executing'
      end

      def can_queue?
        status != 'executing'
      end
    end
  end
end
