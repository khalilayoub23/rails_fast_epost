# Example: Tasks Controller with Turbo support
# Add these patterns to your existing controllers

module TurboFrameExamples
  # Example 1: Inline editing with Turbo Frames
  def edit
    @task = Task.find(params[:id])

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          @task,
          partial: "tasks/form",
          locals: { task: @task }
        )
      end
    end
  end

  # Example 2: Create with Turbo Stream
  def create
    @task = Task.new(task_params)

    respond_to do |format|
      if @task.save
        format.html { redirect_to tasks_path, notice: "Task created successfully." }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.prepend("tasks_list", partial: "tasks/task", locals: { task: @task }),
            turbo_stream.update("task_form", partial: "tasks/form", locals: { task: Task.new }),
            turbo_stream.append("flash-messages", partial: "shared/flash_message",
                               locals: { type: :success, message: "Task created successfully." })
          ]
        end
      else
        format.html { render :new, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "task_form",
            partial: "tasks/form",
            locals: { task: @task }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  # Example 3: Update with Turbo Stream
  def update
    @task = Task.find(params[:id])

    respond_to do |format|
      if @task.update(task_params)
        format.html { redirect_to tasks_path, notice: "Task updated successfully." }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace(@task, partial: "tasks/task", locals: { task: @task }),
            turbo_stream.append("flash-messages", partial: "shared/flash_message",
                               locals: { type: :success, message: "Task updated successfully." })
          ]
        end
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            @task,
            partial: "tasks/form",
            locals: { task: @task }
          ), status: :unprocessable_entity
        end
      end
    end
  end

  # Example 4: Delete with Turbo Stream
  def destroy
    @task = Task.find(params[:id])
    @task.destroy

    respond_to do |format|
      format.html { redirect_to tasks_path, notice: "Task deleted successfully." }
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.remove(@task),
          turbo_stream.append("flash-messages", partial: "shared/flash_message",
                             locals: { type: :success, message: "Task deleted successfully." })
        ]
      end
    end
  end

  # Example 5: Search with Turbo Frame
  def search
    @tasks = Task.where("title LIKE ?", "%#{params[:q]}%").limit(10)

    respond_to do |format|
      format.html { render :index }
      format.turbo_stream do
        render turbo_stream: turbo_stream.replace(
          "tasks_list",
          partial: "tasks/list",
          locals: { tasks: @tasks }
        )
      end
    end
  end

  # Example 6: Pagination with Turbo Frame
  def index
    @tasks = Task.page(params[:page]).per(20)

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.append(
          "tasks_list",
          partial: "tasks/list",
          locals: { tasks: @tasks }
        )
      end
    end
  end

  # Example 7: Modal with Turbo Frame
  def new
    @task = Task.new

    respond_to do |format|
      format.html
      format.turbo_stream do
        render turbo_stream: turbo_stream.update(
          "modal_container",
          partial: "shared/modal",
          locals: {
            title: "New Task",
            content: render_to_string(partial: "tasks/form", locals: { task: @task })
          }
        )
      end
    end
  end
end
