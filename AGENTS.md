# Rails Fast Epost - Agent Guidelines

## Commands
- **Build/Lint**: `bin/rubocop` - Run RuboCop linting with rails-omakase style
- **Test all**: `bin/rails test` - Run all tests (unit, integration, system)
- **Single test**: `bin/rails test test/path/to/test_file.rb` or `bin/rails test test/path/to/test_file.rb:line_number`
- **System tests**: `bin/rails test:system` - Run browser-based tests with Capybara/Selenium
- **Server**: `bin/dev` - Start development server
- **Console**: `bin/rails console` - Interactive Rails console
- **Setup**: `bin/setup` - Initial project setup (dependencies, DB)

## Architecture
- **Framework**: Rails 8.0.1 with Ruby 3.3.4
- **Database**: PostgreSQL with multiple databases (main, cache, queue, cable)
- **Frontend**: Turbo + Stimulus (Hotwire), Importmap for JS, Propshaft for assets
- **Background Jobs**: Solid Queue (DB-backed)
- **Caching**: Solid Cache (DB-backed)
- **WebSocket**: Solid Cable (DB-backed)
- **Deployment**: Kamal with Docker, Thruster for production

## Code Style
- Follow rubocop-rails-omakase style (inherits from Gemfile)
- Standard Rails MVC structure: models in `app/models`, controllers in `app/controllers`
- Use Rails conventions: snake_case for files/methods, PascalCase for classes
- Tests use minitest framework with fixtures, parallel execution enabled
- Security: Use Brakeman for vulnerability scanning
