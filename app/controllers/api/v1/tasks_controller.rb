module Api
  module V1
    class TasksController < BaseController
      before_action :authenticate_user!
      before_action :set_task, only: %i[show update destroy]

      def index
        authorize Task
        render json: policy_scope(Task)
      end

      def show
        authorize @task
        render json: @task
      end

      def create
        task = Task.new(task_params)
        authorize task
        if task.save
          render json: task, status: :created
        else
          render_errors!(task)
        end
      end

      def update
        authorize @task
        if @task.update(task_params)
          render json: @task
        else
          render_errors!(@task)
        end
      end

      def destroy
        authorize @task
        @task.destroy
        head :no_content
      end

      private

      def set_task
        @task = policy_scope(Task).find(params[:id])
      end

      def task_params
        params.require(:task).permit(:customer_id, :carrier_id, :package_type, :start, :target, :failure_code, :delivery_time, :status, :barcode, :filled_form_url)
      end
    end
  end
end
