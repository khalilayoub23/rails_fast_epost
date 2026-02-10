class RemarksController < ApplicationController
  include Respondable

  before_action :set_task
  before_action :set_remark, only: %i[show edit update destroy]

  def index
    authorize Remark
    @remarks = @task.remarks
    respond_with_index(@remarks)
  end

  def show
    authorize @remark
    respond_with_show(@remark)
  end

  def new
    @remark = @task.remarks.new
    authorize @remark
  end

  def create
    @remark = @task.remarks.new(remark_params)
    authorize @remark
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
    authorize @remark
    respond_with_update(@remark, @task, notice: "Remark updated.", attributes: remark_params) do
      render turbo_stream: [
        turbo_stream.replace(@remark, partial: "remarks/remark_card", locals: { remark: @remark, task: @task }),
        turbo_stream.append("flash-messages", partial: "shared/flash_message",
                           locals: { type: :success, message: "Remark updated successfully!" })
      ]
    end
  end

  def destroy
    authorize @remark
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
    authorize @task, :show?
  end

  def set_remark
    @remark = @task.remarks.find(params[:id])
  end

  def remark_params
    params.require(:remark).permit(:content, :remarkable_type, :remarkable_id)
  end
end
