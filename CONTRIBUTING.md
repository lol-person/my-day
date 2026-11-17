# Contributing

Contributions are welcome. Please discuss substantial changes before opening a pull request.

## Development checks

```bash
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
```

## Project requirements

- Preserve the local-first architecture.
- Do not introduce mandatory accounts, backend services or telemetry.
- Use Drift for persistent storage.
- Never manually edit generated Drift code.
- Preserve existing user data and database migrations.
- Preserve JSON backup import compatibility for versions 1 through 4.
- Preserve transactional restore behavior.
- Preserve local notification functionality.
- Avoid unnecessary dependencies and unrelated refactoring.

## Database changes

Database changes require schema migrations, safe defaults and relevant tests.
Regenerate Drift files using the existing generator.

## Pull requests

Explain the change, its purpose, relevant tests and any data migration implications.
Never include personal databases, JSON backups, signing keys or passwords.
