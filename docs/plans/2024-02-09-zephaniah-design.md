# Zephaniah Design Document

**Date:** 2024-02-09
**App Name:** Zephaniah
**Framework:** Flutter (no Python backend)

## Overview

Zephaniah is a Flutter desktop application for searching, downloading, and viewing public documents related to Jeffrey Epstein from government and institutional sources. The app supports multiple search engines, institutional filtering, and is MCP-extensible for adding custom search providers.

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                      Zephaniah App                          │
├─────────────────────────────────────────────────────────────┤
│  UI Layer (Pages + Widgets)                                 │
│    - SearchPage (search + institution cards)                │
│    - ResultsPage (search results)                           │
│    - ArtifactsPage (downloaded files)                       │
│    - ViewerPage (PDF/media viewer)                          │
│    - HistoryPage (past searches)                            │
│    - SnapshotsPage (daily snapshots)                        │
│    - McpPage (MCP provider management)                      │
│    - SettingsPage + AboutPage                               │
├─────────────────────────────────────────────────────────────┤
│  Services Layer (Singleton + ChangeNotifier)                │
│    - SearchService (query construction, HTTP parsing)       │
│    - DownloadService (file downloads, progress, queue)      │
│    - StorageService (SQLite + file management)              │
│    - McpService (MCP protocol, extensible providers)        │
│    - LogService (system logging)                            │
│    - SettingsService (app configuration)                    │
├─────────────────────────────────────────────────────────────┤
│  Data Layer                                                 │
│    - SQLite database (artifacts, searches, history)         │
│    - Local file storage (~/Zephaniah/artifacts/YYYY-MM-DD/) │
└─────────────────────────────────────────────────────────────┘
```

## Technology Decisions

| Aspect | Decision | Rationale |
|--------|----------|-----------|
| State Management | Singleton Services + setState | Simple, like HardEvidence |
| PDF Viewer | Syncfusion Flutter PDF Viewer | Feature-rich, text selection |
| Media Player | media_kit | Unified audio/video |
| Database | SQLite | Local, reliable |
| Theme | Light + dark navy seed + amber accents | Professional investigative feel |

## Search System

### Query Construction
```
"[search terms]" site:[institution] filetype:[type] [time_range]
```

Example:
```
"Jeffrey Epstein flight logs" site:fbi.gov OR site:justice.gov filetype:pdf
```

### Pre-configured Institutions

| Category | Color | Institutions |
|----------|-------|--------------|
| Law Enforcement | Red (#D32F2F) | FBI, DEA, US Marshals |
| Justice | Purple (#8E24AA) | DOJ, Federal Courts, State AGs |
| Intelligence | Dark Blue (#1565C0) | CIA reading room, DNI |
| Financial | Green (#558B2F) | SEC, FinCEN, Treasury |
| State/Diplomatic | Teal (#00897B) | State Dept, Embassy cables |
| Archives | Brown (#6D4C41) | National Archives, FOIA libraries |
| Legislative | Orange (#E65100) | Congress.gov, Senate/House records |
| International | Amber (#FF8F00) | Interpol, UK courts, foreign gov |

### Search Providers
- Built-in: Google, Bing, DuckDuckGo
- MCP: Added via UI (JSON-RPC 2.0)

## Download Queue

- Concurrent download limit (configurable, default: 3)
- Per-file progress tracking
- Pause/Resume/Cancel
- Automatic retry on failure
- States: queued, downloading, paused, completed, failed

## Daily Snapshot Feature

One-click button to:
1. Run search with saved terms across all enabled institutions
2. Download all new artifacts (skip duplicates)
3. Save as dated snapshot record

## Storage Structure

```
~/Zephaniah/
├── artifacts/
│   ├── 2024-02-09/
│   │   ├── epstein_flight_logs.pdf
│   │   └── ...
│   └── ...
├── database/
│   └── zephaniah.db
└── logs/
    └── zephaniah.log
```

## Database Schema

```sql
-- Search history
CREATE TABLE searches (
  id TEXT PRIMARY KEY,
  query_terms TEXT NOT NULL,
  file_types TEXT,
  time_range TEXT,
  institutions TEXT,
  search_engine TEXT,
  created_at TEXT NOT NULL,
  result_count INTEGER DEFAULT 0
);

-- Downloaded artifacts
CREATE TABLE artifacts (
  id TEXT PRIMARY KEY,
  search_id TEXT,
  filename TEXT NOT NULL,
  original_url TEXT NOT NULL,
  source_institution TEXT,
  file_type TEXT,
  file_size INTEGER,
  file_path TEXT NOT NULL,
  downloaded_at TEXT NOT NULL,
  status TEXT DEFAULT 'completed',
  metadata_json TEXT,
  FOREIGN KEY (search_id) REFERENCES searches(id)
);

-- Snapshots
CREATE TABLE snapshots (
  id TEXT PRIMARY KEY,
  snapshot_date TEXT NOT NULL,
  search_terms TEXT,
  institutions_used TEXT,
  artifacts_found INTEGER DEFAULT 0,
  artifacts_downloaded INTEGER DEFAULT 0,
  new_artifacts INTEGER DEFAULT 0,
  duplicates_skipped INTEGER DEFAULT 0,
  started_at TEXT NOT NULL,
  completed_at TEXT,
  status TEXT DEFAULT 'running'
);

-- Custom institutions
CREATE TABLE custom_institutions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  url_pattern TEXT NOT NULL,
  color_hex TEXT,
  category TEXT,
  created_at TEXT NOT NULL
);

-- MCP providers
CREATE TABLE mcp_providers (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  endpoint_url TEXT NOT NULL,
  enabled INTEGER DEFAULT 1,
  config_json TEXT,
  added_at TEXT NOT NULL
);
```

## UI Layout

```
┌────────────────────────────────────────────────────────────────┐
│ Sidebar (220px)  │  Main Content Area                          │
│                  │                                              │
│ ┌──────────────┐ │  ┌────────────────────────────────────────┐ │
│ │ Search       │ │  │                                        │ │
│ │ Artifacts    │ │  │         Active Page Content            │ │
│ │ History      │ │  │                                        │ │
│ │ Snapshots    │ │  │                                        │ │
│ │ ─────────── │ │  │                                        │ │
│ │ MCP         │ │  ├────────────────────────────────────────┤ │
│ │ Settings    │ │  │ Download Queue Panel (collapsible)     │ │
│ │ About       │ │  ├────────────────────────────────────────┤ │
│ └──────────────┘ │  │ Logs Panel (collapsible)               │ │
└────────────────────────────────────────────────────────────────┘
```

## Theme

- Light base theme
- Seed color: `Color(0xFF1a1a2e)` (dark navy)
- Accent: `Color(0xFFFF8F00)` (amber/gold)
- Material 3 design

## About Page Notes

- Syncfusion Community License notice
- Free for individuals and businesses < $1M revenue
- Link to syncfusion.com/license

## Test Coverage

- All services: SearchService, DownloadService, StorageService, McpService, SettingsService, LogService
- All providers: Google, Bing, DuckDuckGo
- All models: SearchResult, Artifact, Snapshot, Institution
- Database operations
- Key widgets

## File Structure

```
lib/
├── main.dart
├── models/
│   ├── search_result.dart
│   ├── artifact.dart
│   ├── snapshot.dart
│   ├── institution.dart
│   ├── search_query.dart
│   └── download_task.dart
├── services/
│   ├── search_service.dart
│   ├── download_service.dart
│   ├── storage_service.dart
│   ├── database_service.dart
│   ├── mcp_service.dart
│   ├── settings_service.dart
│   └── log_service.dart
├── providers/
│   ├── search_provider.dart (abstract)
│   ├── google_search_provider.dart
│   ├── bing_search_provider.dart
│   └── duckduckgo_search_provider.dart
├── pages/
│   ├── search_page.dart
│   ├── results_page.dart
│   ├── artifacts_page.dart
│   ├── viewer_page.dart
│   ├── history_page.dart
│   ├── snapshots_page.dart
│   ├── mcp_page.dart
│   ├── settings_page.dart
│   └── about_page.dart
└── widgets/
    ├── sidebar.dart
    ├── institution_card.dart
    ├── institution_cards_grid.dart
    ├── file_type_selector.dart
    ├── time_range_selector.dart
    ├── search_result_card.dart
    ├── artifact_card.dart
    ├── download_queue_panel.dart
    ├── download_item.dart
    ├── logs_panel.dart
    ├── pdf_viewer_widget.dart
    └── media_player_widget.dart
```
