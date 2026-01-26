class PaymentsTasksController < ApplicationController
  def create
    @payments_task = PaymentsTask.new(payments_task_params)
    authorize @payments_task
    if @payments_task.save
      respond_to do |format|
        format.html { redirect_back fallback_location: task_path(@payments_task.task), notice: "Linked payment to task." }
        format.json { render json: @payments_task, status: :created }
      end
    else
      respond_to do |format|
        format.html { render plain: @payments_task.errors.full_messages.join(", "), status: :unprocessable_entity }
        format.json { render json: { errors: @payments_task.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @payments_task = PaymentsTask.find(params[:id])
    authorize @payments_task
    task = @payments_task.task
    @payments_task.destroy
    respond_to do |format|
      format.html { redirect_back fallback_location: task_path(task), notice: "Unlinked payment from task." }
      format.json { head :no_content }
    end
  end

  private

  def payments_task_params
    params.require(:payments_task).permit(:task_id, :payment_id)
  end
end
