class RemarksController < ApplicationController
  before_action :set_task
  before_action :set_remark, only: %i[show edit update destroy]

  def index
    @remarks = @task.remarks
    respond_to do |format|
      format.html
      format.json { render json: @remarks }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @remark }
    end
  end

  def new
    @remark = @task.remarks.new
  end

  def create
    @remark = @task.remarks.new(remark_params)
    if @remark.save
      respond_to do |format|
        format.html { redirect_to [ @task, @remark ], notice: "Remark created." }
        format.json { render json: @remark, status: :created }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.append("remarks_list", partial: "remarks/remark_card", locals: { remark: @remark, task: @task }),
            turbo_stream.update("remark_form", partial: "remarks/form", locals: { remark: @task.remarks.new, task: @task }),
            turbo_stream.append("flash-messages", partial: "shared/flash_message",
                               locals: { type: :success, message: "Remark added successfully!" })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @remark.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "remark_form",
            partial: "remarks/form",
            locals: { remark: @remark, task: @task }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def edit; end

  def update
    if @remark.update(remark_params)
      respond_to do |format|
        format.html { redirect_to [ @task, @remark ], notice: "Remark updated." }
        format.json { render json: @remark }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@remark, partial: "remarks/remark_card", locals: { remark: @remark, task: @task }),
            turbo_stream.append("flash-messages", partial: "shared/flash_message",
                               locals: { type: :success, message: "Remark updated successfully!" })
          ]
        end
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @remark.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            @remark,
            partial: "remarks/form",
            locals: { remark: @remark, task: @task }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  def destroy
    @remark.destroy
    respond_to do |format|
      format.html { redirect_to task_remarks_path(@task), notice: "Remark deleted." }
      format.json { head :no_content }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@remark),
          turbo_stream.append("flash-messages", partial: "shared/flash_message",
                             locals: { type: :success, message: "Remark deleted successfully!" })
        ]
      end
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
