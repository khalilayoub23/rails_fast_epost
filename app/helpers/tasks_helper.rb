module TasksHelper
  TASK_DOCUMENT_PHASES = {
    created: {
      title: "Task Created",
      patterns: [ "-created-" ]
    },
    status_updates: {
      title: "Status Updates",
      patterns: [ "-pending-", "-in-transit-", "-failed-", "-returned-", "-postponed-" ]
    },
    payment: {
      title: "Payment",
      patterns: [ "-payment-succeeded-" ]
    },
    completion: {
      title: "Completion",
      patterns: [ "completion-certificate", "-delivered-" ]
    }
  }.freeze

  def grouped_task_legal_files(legal_files)
    grouped = Hash.new { |hash, key| hash[key] = [] }

    legal_files.each do |file|
      grouped[task_document_phase_for(file)] << file
    end

    ordered = TASK_DOCUMENT_PHASES.keys.filter_map do |phase_key|
      files = grouped[phase_key]
      next if files.blank?

      [ phase_key, TASK_DOCUMENT_PHASES.fetch(phase_key).fetch(:title), files ]
    end

    if grouped[:other].present?
      ordered << [ :other, "Other Documents", grouped[:other] ]
    end

    ordered
  end

  private

  def task_document_phase_for(file)
    normalized_name = file.filename.to_s.downcase.tr("_", "-")

    TASK_DOCUMENT_PHASES.each do |phase_key, config|
      return phase_key if config.fetch(:patterns).any? { |pattern| normalized_name.include?(pattern) }
    end

    :other
  end
end
