# API Endpoints

- `POST /api/register/` – Request an OTP; body: `{ "phone_number": "..." }`
- `POST /api/verify/` – Verify OTP and obtain token; body: `{ "phone_number": "...", "code": "..." }`
- `POST /api/profile/` – Fetch current user profile.
- `POST /api/profile/update/` – Update profile; body includes `username` and `email`.
- `GET/POST /api/visit/` – List or create visits.
- `POST /api/chat/msg/` – Send a chat message.
- `GET /health` – Health check endpoint.

Authentication is handled via `Authorization` headers using Bearer tokens.
Responses are JSON formatted.
