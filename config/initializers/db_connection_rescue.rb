# Rescue PG/ActiveRecord connection errors early and return a friendly 503 page in development
if Rails.env.development?
  class DbConnectionRescue
    def initialize(app)
      @app = app
    end

    def call(env)
      begin
        @app.call(env)
      rescue ActiveRecord::ConnectionNotEstablished, PG::ConnectionBad => e
        Rails.logger.warn("DbConnectionRescue: #{e.class} - #{e.message}")
        body = File.read(Rails.root.join("public", "503_db.html")) rescue "Database unavailable"
        [ 503, { "Content-Type" => "text/html" }, [ body ] ]
      end
    end
  end

  Rails.application.config.middleware.insert_before(0, DbConnectionRescue)
end
