# Database / API

## Current Status

No API integration exists in the Flutter project yet.

- No HTTP client package (e.g. `http`, `dio`) in `pubspec.yaml`
- No API base URL configuration
- No login/authentication code
- No Dart API models
- No services/repositories for CRUD
- No token/session storage

## Planned Backend (Project Rules)

Per `.cursor/rules/rules.mdc`, the intended backend is:

- **Backend:** .NET Core Web API
- **Communication:** HTTP/REST

Planned API responsibilities (not yet wired in Flutter):

- Login / Authentication
- Fetch, Insert, Update, Delete, Search (CRUD)

## Conventions To Follow When API Is Added

Document only as rules for future work; nothing below is implemented yet.

### Integration Rules

- Use the provided .NET Core Web API for all data and business operations.
- Do not write SQL or talk to SQL Server from Flutter.
- Do not invent endpoints, parameters, or response fields.
- Match Dart models to actual API request/response shapes.

### Authentication Rules

- Use the provided login endpoint.
- Store tokens securely when required.
- Attach auth info on protected requests.
- Handle unauthorized/expired sessions.
- Never hard-code credentials, API keys, or tokens.

### HTTP Method Pattern

| Method | Use |
|--------|-----|
| GET | Fetch |
| POST | Insert |
| PUT/PATCH | Update |
| DELETE | Delete |

### Error Handling Expectations

Handle and surface user-friendly states for: Loading, Success, Empty, Validation Error, Unauthorized, Server Error, Network Error.

## Notes

When API endpoints and contracts are available, update this file with:

- Base URL configuration location
- Actual endpoints
- Request/response models
- Auth/token flow
- Error handling implementation details
