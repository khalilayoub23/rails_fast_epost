module Api
  module V1
    class TasksController < BaseController
      before_action :set_task, only: %i[show update destroy]

      def index
        render json: Task.all
      end

      def show
        render json: @task
      end

      def create
        task = Task.new(task_params)
        if task.save
          render json: task, status: :created
        else
          render_errors!(task)
        end
      end

      def update
        if @task.update(task_params)
          render json: @task
        else
          render_errors!(@task)
        end
      end

      def destroy
        @task.destroy
        head :no_content
      end

      private

      def set_task
        @task = Task.find(params[:id])
      end

      def task_params
        params.require(:task).permit(:customer_id, :carrier_id, :package_type, :start, :target, :failure_code, :delivery_time, :status, :barcode, :filled_form_url)
      end
    end
  end
end
