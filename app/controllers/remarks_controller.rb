class RemarksController < ApplicationController
  include Respondable

  before_action :set_task
  before_action :set_remark, only: %i[show edit update destroy]

  def index
    @remarks = @task.remarks
    respond_with_index(@remarks)
  end

  def show
    respond_with_show(@remark)
  end

  def new
    @remark = @task.remarks.new
  end

  def create
    @remark = @task.remarks.new(remark_params)
    respond_with_create(@remark, @task, notice: "Remark created.") do
      render turbo_stream: [
        turbo_stream.append("remarks_list", partial: "remarks/remark_card", locals: { remark: @remark, task: @task }),
        turbo_stream.update("remark_form", partial: "remarks/form", locals: { remark: @task.remarks.new, task: @task }),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: "Remark added successfully!" })
      ]
    end
  end

  def edit; end

  def update
    respond_with_update(@remark, @task, notice: "Remark updated.") do
      render turbo_stream: [
        turbo_stream.replace(@remark, partial: "remarks/remark_card", locals: { remark: @remark, task: @task }),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: "Remark updated successfully!" })
      ]
      remark_params
    end
  end

  def destroy
    respond_with_destroy(@remark, task_remarks_path(@task), notice: "Remark deleted.") do
      render turbo_stream: [
        turbo_stream.remove(@remark),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: "Remark deleted successfully!" })
      ]
    end
  end

  private

  def set_task
    @task = Task.find(params[:task_id])
  end

  def set_remark
    @remark = @task.remarks.find(params[:id])
  end

  def remark_params
    params.require(:remark).permit(:content, :remarkable_type, :remarkable_id)
  end
end
