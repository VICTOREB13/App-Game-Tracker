# Project: App Game Tracker (v3.3.0)

## Architecture
- **Framework & Platform:** Flutter 3.47+ (Windows Desktop x64, Android).
- **Architecture Pattern:** Local-First Reactive Architecture with SQLite Engine (`sqflite` / `sqflite_common_ffi`), Service Layer for external API integrations (Steam, HLTB, RAWG, Wikipedia), and State Management via `StatefulWidget` / `ChangeNotifier` / Services.
- **Visual Identity:** Victor Engineer (Obsidian Zinc Dark Mode `#09090B`, Crisp Zinc Light Mode `#FAFAFA`, Crimson Accent `#DC2626`, Google Fonts `Outfit` + `Inter`).
- **Data Persistence:** SQLite database (`app_game_tracker.db` / `tracker.db`) with B-Tree indexes, JSON backup/export, local cover art cache (`app_documents/covers/`).

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | SQLite Engine & Sentinel CRUD | Local-first persistence, Sentinel copyWith, null clearing, indexes, transactions | M1 | ORIGINAL_REQUEST §R1.1 |
| 2 | Network Resilience & APIs | Resilient clients for Steam, HLTB, RAWG, Wikipedia with timeouts, rate-limits & safe parsing | M1 | ORIGINAL_REQUEST §R1.2 |
| 3 | Flutter Architecture & 60 FPS | Widget lifecycles, memory cleanup, controllers disposal, efficient list rendering | M1 | ORIGINAL_REQUEST §R1.3 |
| 4 | Local Security & Secrets | Safe storage for Steam/RAWG keys, SQL sanitization, data privacy | M1 | ORIGINAL_REQUEST §R1.4 |
| 5 | Code Quality & Tests | Static analysis clean, comprehensive unit & widget test coverage | M1 | ORIGINAL_REQUEST §R1.5 |
| 6 | Implementation Roadmap & Tasks | Structured multi-phase plan in implementation_plan.md and task.md | M2, M3 | ORIGINAL_REQUEST §R2 |

## Milestones
| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| 1 | M1: Technical Audit Phase | Multidimensional technical audit across 5 dimensions, static analysis, test evaluation | none | DONE |
| 2 | M2: Audit Consolidation | Formal audit report in artifacts/audit_reports/audit_report_codebase.md | M1 | DONE |
| 3 | M3: Planning & Roadmap | Comprehensive implementation plan & atomic tasks in artifacts/planning/ | M2 | DONE |
| 4 | M4: Final Review & Quality Gate | Final verification, zero lib changes check, handoff to Sentinel | M3 | DONE |

## Code Layout (MVC Pattern)
- `app/lib/main.dart`: App entry point, theme initialization, window configuration.
- `app/lib/models/`: Data models (`game.dart`, `game_sanitizer.dart`, `game_details_result.dart`).
- `app/lib/controllers/`: Business logic and state management (`dashboard_controller.dart`, `game_detail_controller.dart`, `game_search_controller.dart`, `settings_controller.dart`, `analytics_controller.dart`).
- `app/lib/views/screens/`: UI Screens (`dashboard_screen.dart`, `game_detail_screen.dart`, `search_screen.dart`, `settings_screen.dart`, `analytics_screen.dart`, `setup_screen.dart`).
- `app/lib/views/widgets/`: Modular UI components across dashboard, game_detail, search, and settings.
- `app/lib/services/`: Services (`database_service.dart`, `steam_service.dart`, `hltb_service.dart`, `metadata_service.dart`, `backup_service.dart`, `secure_storage_service.dart`, `string_normalizer.dart`, `theme_manager.dart`).
- `app/test/`: Automated test suite (17 deterministic test suites).
- `artifacts/`: Project artifacts (architecture, planning, audit reports).
