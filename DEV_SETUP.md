Local dev setup (Docker)

1. Copy environment sample:

   cp .env.sample .env

2. Start services:

   docker compose -f docker-compose.dev.yml up --build

3. In another terminal, run DB setup/migrate and seed if needed:

   docker compose -f docker-compose.dev.yml run --rm web bin/rails db:create db:migrate db:seed

4. Start workers (if not started as a service):

   docker compose -f docker-compose.dev.yml run --rm worker

Notes:
- Ensure `config/master.key` is set as env `RAILS_MASTER_KEY` in `.env` or use `bin/rails credentials:edit` locally.
- This composes a basic stack for running automations (Solid Queue) and the web server.
