module Respondable
  extend ActiveSupport::Concern

  private

  def respond_with_index(resources)
    respond_to do |format|
      format.html
      format.json { render json: resources }
    end
  end

  def respond_with_show(resource)
    respond_to do |format|
      format.html
      format.json { render json: resource }
    end
  end

  def respond_with_create(resource, parent = nil, notice: nil, &turbo_stream_block)
    notice ||= "#{resource.class.name} created."

    if resource.save
      respond_to do |format|
        format.html { redirect_to [ parent, resource ].compact, notice: notice }
        format.json { render json: resource, status: :created }
        format.turbo_stream(&turbo_stream_block) if turbo_stream_block
      end
    else
      respond_to do |format|
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream { render turbo_stream: turbo_stream.replace("#{resource.model_name.param_key}_form", partial: "#{resource.model_name.plural}/form", locals: { resource.model_name.param_key.to_sym => resource, (parent.model_name.param_key.to_sym if parent) => parent }.compact), status: :unprocessable_entity } if turbo_stream_block
      end
    end
  end

  def respond_with_update(resource, parent = nil, notice: nil, attributes:, &turbo_stream_block)
    notice ||= "#{resource.class.name} updated."

    if resource.update(attributes)
      respond_to do |format|
        format.html { redirect_to [ parent, resource ].compact, notice: notice }
        format.json { render json: resource }
        format.turbo_stream(&turbo_stream_block) if turbo_stream_block
      end
    else
      respond_to do |format|
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: { errors: resource.errors.full_messages }, status: :unprocessable_entity }
        if turbo_stream_block
          format.turbo_stream do
            render turbo_stream: turbo_stream.replace(
              resource,
              partial: "#{resource.model_name.plural}/form",
              locals: { resource.model_name.param_key.to_sym => resource, (parent.model_name.param_key.to_sym if parent) => parent }.compact
            ), status: :unprocessable_entity
          end
        end
      end
    end
  end

  def respond_with_destroy(resource, redirect_path, notice: nil, &turbo_stream_block)
    notice ||= "#{resource.class.name} deleted."
    resource.destroy

    respond_to do |format|
      format.html { redirect_to redirect_path, notice: notice }
      format.json { head :no_content }
      format.turbo_stream(&turbo_stream_block) if turbo_stream_block
    end
  end
end
