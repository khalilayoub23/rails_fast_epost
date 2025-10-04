class TasksController < ApplicationController
  before_action :set_customer, only: %i[index new create]
  before_action :set_task, only: %i[show edit update destroy update_status update_delivery]

  def index
    @tasks = if @customer
      @customer.tasks
    else
      Task.all
    end
    respond_to do |format|
      format.html
      format.json { render json: @tasks }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @task }
    end
  end

  def new
    @task = (@customer ? @customer.tasks : Task).new
  end

  def create
    scope = @customer ? @customer.tasks : Task
    @task = scope.new(task_params)
    if @task.save
      respond_to do |format|
        format.html { redirect_to @task, notice: "Task created." }
        format.json { render json: @task, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @task.update(task_params)
      respond_to do |format|
        format.html { redirect_to @task, notice: "Task updated." }
        format.json { render json: @task }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @task.destroy
    respond_to do |format|
      format.html { redirect_to(@task.customer ? customer_tasks_path(@task.customer) : tasks_path, notice: "Task deleted.") }
      format.json { head :no_content }
    end
  end

  def update_status
    if @task.update(status: params[:status])
      redirect_to @task, notice: "Task status updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  def update_delivery
    if @task.update(delivery_time: params[:delivery_time], failure_code: params[:failure_code])
      redirect_to @task, notice: "Task delivery updated."
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_customer
    @customer = Customer.find(params[:customer_id]) if params[:customer_id]
  end

  def set_task
    @task = Task.find(params[:id])
  end

  def task_params
    params.require(:task).permit(:customer_id, :carrier_id, :package_type, :start, :target, :failure_code, :delivery_time, :status, :barcode, :filled_form_url)
  end
end
