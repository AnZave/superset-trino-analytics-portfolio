# Security notes

- Never commit `.env`; it contains local credentials and the Telegram bot token.
- Copy `.env.example` to `.env` and replace every placeholder before startup.
- Rotate a Telegram token immediately if it is disclosed in chat, logs, or screenshots.
- The included Superset and Trino setup is intended for local portfolio use, not
  direct internet exposure.
- For production, add TLS, SSO, network isolation, secret management, and
  least-privilege database accounts.
