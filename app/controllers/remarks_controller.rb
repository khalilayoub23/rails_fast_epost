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
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @remark.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @remark.update(remark_params)
      respond_to do |format|
        format.html { redirect_to [ @task, @remark ], notice: "Remark updated." }
        format.json { render json: @remark }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @remark.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @remark.destroy
    respond_to do |format|
      format.html { redirect_to task_remarks_path(@task), notice: "Remark deleted." }
      format.json { head :no_content }
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
