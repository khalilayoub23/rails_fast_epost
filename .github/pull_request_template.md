## Summary

- What does this PR change and why?
- Link to related issues or discussions.

## Changes

- [ ] Code
- [ ] Tests
- [ ] Docs (README/CHANGELOG)
- [ ] Config/CI

## Screenshots/Recordings (if UI)

Add before/after screenshots or a short clip.

## How to test

Provide concise steps. For example:

1. bin/setup
2. bin/rails db:prepare
3. bin/rails test
4. bin/dev and visit http://localhost:3000

## Risk assessment

- What can break? Any migrations or data backfills?
- Rollback plan?

## Security & secrets

- Any new secrets or keys? Document env vars and ensure they are set in CI.
- If adding webhooks (e.g., Stripe), confirm signature verification and idempotency guards.

## Deployment notes

- Kamal/Thruster specifics, if any
- Background jobs or scheduler changes

## Checklist

- [ ] RuboCop passes (bin/rubocop)
- [ ] Tests are green (bin/rails test)
- [ ] Brakeman scan clean (bin/brakeman)
- [ ] No secrets committed
