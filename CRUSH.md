# CRUSH.md

Build/Test/Lint (Flutter/Dart)
- Install deps: flutter pub get
- Generate code: dart run build_runner build --delete-conflicting-outputs
- Apply fixes: dart fix --apply
- Format: dart format --set-exit-if-changed .
- Analyze: flutter analyze --no-fatal-infos
- Unit/widget tests: flutter test
- Run a single test file: flutter test test/services/auth_service_test.dart
- Run a single test by name: flutter test --plain-name "<test name>"
- Integration tests (Flutter): flutter test integration_test
- Patrol integration (if used locally): dart run patrol test
- Clean build: flutter clean && flutter pub get

Code Style Guidelines (Dart/Flutter)
- Lints: include package very_good_analysis; analyzer disallows implicit-casts and implicit-dynamic; treat dead_code/unused_* as errors; see analysis_options.yaml
- Imports: prefer package: imports; relative allowed temporarily; avoid unused imports; group dart:, package:, project; no wildcards
- Formatting: use dart format; require trailing commas where possible (encouraged even if not enforced); max line length flexible per current config
- Types: no implicit dynamic; add explicit types for public APIs; favor final and const; avoid dynamic calls
- Naming: lowerCamelCase for vars/funcs, UpperCamelCase for types, UPPER_SNAKE for const; file names snake_case
- Error handling: never swallow errors; use Result types in core/types/result.dart or return Either-like patterns; prefer app_error.dart for domain errors; avoid print, use core/services/logger.dart or smart_logger.dart
- State/routing: Riverpod for state; go_router for navigation; central routes in core/router/app_router.dart
- Serialization: use dart_mappable; rerun build_runner on model changes; exclude generated files from review
- Env/secrets: load via flutter_dotenv; never commit secrets; follow .gitignore rules
- Testing: use flutter_test, mocktail; keep tests fast and deterministic; integration tests live in integration_test/

Tooling notes
- CI mirrors: see .github/workflows/flutter-ci.yml (build_runner, dart fix, format, analyze, test)
- Automated fixes configured in fix_options.yaml

Agent tips
- Use services in lib/core/services/*; models in lib/shared/models/*; features under lib/features/*
- When adding code, follow existing module structure and providers in lib/core/providers/*
