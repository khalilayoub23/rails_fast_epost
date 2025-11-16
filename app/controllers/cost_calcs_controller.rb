class CostCalcsController < ApplicationController
  include Respondable

  before_action :set_task
  before_action :set_cost_calc, only: %i[show edit update destroy]

  def index
    @cost_calcs = [ @task.cost_calc ].compact
    respond_with_index(@cost_calcs)
  end

  def show
    respond_with_show(@cost_calc)
  end

  def new
    @cost_calc = @task.build_cost_calc
  end

  def create
    @cost_calc = @task.build_cost_calc(cost_calc_params)
    respond_with_create(@cost_calc, @task, notice: "Cost calc created.")
  end

  def edit; end

  def update
    respond_with_update(@cost_calc, @task, notice: "Cost calc updated.") do
      cost_calc_params
    end
  end

  def destroy
    respond_with_destroy(@cost_calc, task_cost_calcs_path(@task), notice: "Cost calc deleted.")
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
