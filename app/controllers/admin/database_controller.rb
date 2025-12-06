module Admin
  class DatabaseController < ApplicationController
    before_action :require_admin!

    # Allowlist of model classes that can be exported/imported
    # This prevents Remote Code Execution through constantize
    ALLOWED_MODEL_CLASSES = {
      "audit_logs" => "AuditLog",
      "carriers" => "Carrier",
      "carrier_memberships" => "CarrierMembership",
      "carrier_payouts" => "CarrierPayout",
      "carrier_ratings" => "CarrierRating",
      "contact_inquiries" => "ContactInquiry",
      "cost_calcs" => "CostCalc",
      "customers" => "Customer",
      "deliveries" => "Delivery",
      "documents" => "Document",
      "document_templates" => "DocumentTemplate",
      "forms" => "Form",
      "form_templates" => "FormTemplate",
      "integration_events" => "IntegrationEvent",
      "lawyers" => "Lawyer",
      "messengers" => "Messenger",
      "notification_logs" => "NotificationLog",
      "notification_preferences" => "NotificationPreference",
      "payments" => "Payment",
      "payment_intents" => "PaymentIntent",
      "payments_tasks" => "PaymentsTask",
      "phones" => "Phone",
      "preferences" => "Preference",
      "proof_uploads" => "ProofUpload",
      "refunds" => "Refund",
      "remarks" => "Remark",
      "senders" => "Sender",
      "signature_events" => "SignatureEvent",
      "tasks" => "Task",
      "tracking_events" => "TrackingEvent",
      "users" => "User"
    }.freeze

    # GET /admin/database
    def index
      @stats = {
        size: database_size,
        tables: table_statistics,
        recent_backups: list_backups
      }
    end

    # POST /admin/database/export
    def export
      format = params[:format] || "sql"
      table = params[:table]

      case format
      when "sql"
        export_sql(table)
      when "csv"
        export_csv(table)
      when "json"
        export_json(table)
      else
        redirect_to admin_database_path, alert: "Invalid export format"
      end
    end

    # POST /admin/database/import
    def import
      uploaded_file = params[:file]

      unless uploaded_file
        redirect_to admin_database_path, alert: "No file uploaded"
        return
      end

      format = File.extname(uploaded_file.original_filename).delete(".")

      case format
      when "sql"
        import_sql(uploaded_file)
      when "csv"
        import_csv(uploaded_file)
      else
        redirect_to admin_database_path, alert: "Unsupported file format"
      end
    end

    # GET /admin/database/backup
    def backup
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      db_name = ActiveRecord::Base.connection.current_database
      backup_dir = Rails.root.join("tmp", "backups")
      FileUtils.mkdir_p(backup_dir)

      backup_file = backup_dir.join("#{db_name}_#{timestamp}.sql")

      # Use pg_dump to create backup
      db_config = ActiveRecord::Base.connection_db_config.configuration_hash
      env = {
        "PGPASSWORD" => db_config[:password].to_s
      }

      cmd = [
        "pg_dump",
        "-h", db_config[:host] || "localhost",
        "-p", (db_config[:port] || 5432).to_s,
        "-U", db_config[:username],
        "-d", db_name,
        "-f", backup_file.to_s,
        "--no-owner",
        "--no-acl"
      ].join(" ")

      success = system(env, cmd)

      if success && File.exist?(backup_file)
        send_file backup_file,
          filename: "#{db_name}_#{timestamp}.sql",
          type: "application/sql",
          disposition: "attachment"
      else
        redirect_to admin_database_path, alert: "Backup failed"
      end
    end

    private

    def export_sql(table = nil)
      timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
      db_name = ActiveRecord::Base.connection.current_database
      filename = table ? "#{table}_#{timestamp}.sql" : "#{db_name}_#{timestamp}.sql"

      sql_content = if table
        export_table_sql(table)
      else
        export_full_sql
      end

      send_data sql_content,
        filename: filename,
        type: "application/sql",
        disposition: "attachment"
    end

    def export_csv(table)
      unless table
        redirect_to admin_database_path, alert: "Table name required for CSV export"
        return
      end

      model_class = safe_model_class(table)
      unless model_class
        redirect_to admin_database_path, alert: "Invalid table name"
        return
      end

      csv_data = generate_csv(model_class)

      send_data csv_data,
        filename: "#{table}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.csv",
        type: "text/csv",
        disposition: "attachment"
    end

    def export_json(table)
      unless table
        redirect_to admin_database_path, alert: "Table name required for JSON export"
        return
      end

      model_class = safe_model_class(table)
      unless model_class
        redirect_to admin_database_path, alert: "Invalid table name"
        return
      end

      data = model_class.all.as_json

      send_data JSON.pretty_generate(data),
        filename: "#{table}_#{Time.current.strftime('%Y%m%d_%H%M%S')}.json",
        type: "application/json",
        disposition: "attachment"
    end

    def export_table_sql(table)
      model_class = safe_model_class(table)
      return "-- Error: Invalid table name" unless model_class

      records = model_class.all

      sql = "-- Export of #{table} table\n"
      sql += "-- Generated at #{Time.current}\n\n"

      records.each do |record|
        columns = record.attributes.keys.join(", ")
        values = record.attributes.values.map { |v| ActiveRecord::Base.connection.quote(v) }.join(", ")
        sql += "INSERT INTO #{quoted_table_name(table)} (#{columns}) VALUES (#{values});\n"
      end

      sql
    end

    def export_full_sql
      sql = "-- Full database export\n"
      sql += "-- Generated at #{Time.current}\n\n"

      ActiveRecord::Base.connection.tables.each do |table|
        next if table == "schema_migrations" || table == "ar_internal_metadata"

        model_class = safe_model_class(table)
        next unless model_class

        sql += "\n-- Table: #{table}\n"
        sql += export_table_sql(table)
      end

      sql
    end

    def generate_csv(model_class)
      require "csv"

      CSV.generate(headers: true) do |csv|
        # Header row
        csv << model_class.column_names

        # Data rows
        model_class.find_each do |record|
          csv << model_class.column_names.map { |col| record.send(col) }
        end
      end
    end

    def import_sql(file)
      # For security, we'll just show a message
      # Actual SQL import should be done via command line
      redirect_to admin_database_path,
        notice: "SQL import must be done via command line: psql -U postgres -d #{ActiveRecord::Base.connection.current_database} < #{file.original_filename}"
    end

    def import_csv(file)
      table = params[:table]
      unless table
        redirect_to admin_database_path, alert: "Table name required for CSV import"
        return
      end

      model_class = safe_model_class(table)
      unless model_class
        redirect_to admin_database_path, alert: "Invalid table name"
        return
      end

      begin
        require "csv"

        csv_content = file.read
        rows = CSV.parse(csv_content, headers: true)

        imported = 0
        rows.each do |row|
          model_class.create!(row.to_h)
          imported += 1
        end

        redirect_to admin_database_path, notice: "Successfully imported #{imported} records into #{table}"
      rescue => e
        redirect_to admin_database_path, alert: "Import failed: #{e.message}"
      end
    end

    def database_size
      sql = "SELECT pg_size_pretty(pg_database_size(current_database()))"
      ActiveRecord::Base.connection.execute(sql).first["pg_size_pretty"]
    rescue
      "Unknown"
    end

    def table_statistics
      stats = []
      ActiveRecord::Base.connection.tables.sort.each do |table|
        next if table == "schema_migrations" || table == "ar_internal_metadata"

        begin
          # Use quote_table_name to safely escape table names for SQL queries
          quoted = quoted_table_name(table)
          count = ActiveRecord::Base.connection.execute("SELECT COUNT(*) FROM #{quoted}").first["count"]
          size = ActiveRecord::Base.connection.execute("SELECT pg_size_pretty(pg_total_relation_size(#{ActiveRecord::Base.connection.quote(table)}))").first["pg_size_pretty"]

          stats << {
            name: table,
            count: count.to_i,
            size: size
          }
        rescue
          # Skip if query fails
        end
      end
      stats
    end

    def list_backups
      backup_dir = Rails.root.join("tmp", "backups")
      return [] unless Dir.exist?(backup_dir)

      Dir.glob(backup_dir.join("*.sql")).map do |file|
        {
          name: File.basename(file),
          size: File.size(file),
          created_at: File.mtime(file)
        }
      end.sort_by { |b| b[:created_at] }.reverse.first(10)
    end

    # Safely get a model class from a table name using the allowlist
    def safe_model_class(table_name)
      return nil if table_name.blank?
      class_name = ALLOWED_MODEL_CLASSES[table_name.to_s]
      return nil unless class_name
      class_name.constantize
    rescue NameError
      nil
    end

    # Safely quote a table name for use in SQL
    def quoted_table_name(table_name)
      ActiveRecord::Base.connection.quote_table_name(table_name)
    end
  end
end
