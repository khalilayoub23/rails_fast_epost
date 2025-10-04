class CostCalcsController < ApplicationController
  before_action :set_task
  before_action :set_cost_calc, only: %i[show edit update destroy]

  def index
    @cost_calcs = [ @task.cost_calc ].compact
    respond_to do |format|
      format.html
      format.json { render json: @cost_calcs }
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json { render json: @cost_calc }
    end
  end

  def new
    @cost_calc = @task.build_cost_calc
  end

  def create
    @cost_calc = @task.build_cost_calc(cost_calc_params)
    if @cost_calc.save
      respond_to do |format|
        format.html { redirect_to [ @task, @cost_calc ], notice: "Cost calc created." }
        format.json { render json: @cost_calc, status: :created }
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: @cost_calc.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def edit; end

  def update
    if @cost_calc.update(cost_calc_params)
      respond_to do |format|
        format.html { redirect_to [ @task, @cost_calc ], notice: "Cost calc updated." }
        format.json { render json: @cost_calc }
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: @cost_calc.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @cost_calc.destroy
    respond_to do |format|
      format.html { redirect_to task_cost_calcs_path(@task), notice: "Cost calc deleted." }
      format.json { head :no_content }
    end
  end

  private

  def set_task
    @task = Task.find(params[:task_id])
  end

  def set_cost_calc
    @cost_calc = @task.cost_calc || @task.build_cost_calc
  end

  def cost_calc_params
    params.fetch(:cost_calc, {}).permit()
  end
end
