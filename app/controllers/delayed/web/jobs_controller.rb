module Delayed
  module Web
    class JobsController < Delayed::Web::ApplicationController
      def batch
        batch_params = params.require(:jobs).permit(:task, id: [])

        if batch_params.dig(:task) == "retry"
          retried = Delayed::Job.where(batch_params.slice(:id)).update_all({
              run_at: Time.now - 1.week,
              locked_at: nil,
              locked_by: nil,
              attempts: 0,
              last_error: nil,
              failed_at: nil
            })
          flash[:notice] = "#{retried} Retried"
        elsif batch_params.dig(:task) == "delete"
          deleted = Delayed::Job.where(batch_params.slice(:id)).delete_all
          flash[:notice] = "#{deleted} Deleted"
        end

        redirect_to jobs_path
      end

      def queue
        if job.can_queue?
          job.queue!
          flash[:notice] = t(:notice, scope: 'delayed/web.flashes.jobs.queued')
        else
          status = t(job.status, scope: 'delayed/web.views.statuses')
          flash[:alert] = t(:alert, scope: 'delayed/web.flashes.jobs.queued', status: status)
        end
        redirect_to jobs_path
      end

      def destroy
        if job.can_destroy?
          job.destroy
          flash[:notice] = t(:notice, scope: 'delayed/web.flashes.jobs.destroyed')
        else
          status = t(job.status, scope: 'delayed/web.views.statuses')
          flash[:alert] = t(:alert, scope: 'delayed/web.flashes.jobs.destroyed', status: status)
        end
        redirect_to jobs_path
      end

      private

      def job
        @job ||= Delayed::Web::Job.find(params[:id])
      end

      helper_method :job

      def jobs
        @jobs ||= params[:job_name].to_s.strip.length > 0 ?
          Delayed::Web::Job.by_job_name(params[:job_name]) :
          Delayed::Web::Job.all
      end

      def job_data
        @job_data ||= Delayed::Web::Job.job_data
      end

      helper_method :jobs, :job_data
    end
  end
end
