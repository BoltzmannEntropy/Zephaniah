# Zephaniah Redesign: Archive-First Approach

**Date:** 2026-02-10
**Status:** Approved

## Overview

Shift from unreliable online search to an archive-first approach: download complete DOJ datasets via ZIP/torrent, then browse locally with a gallery view. Keep search as a secondary feature for discovering new documents.

## Problems with Current Approach

- DuckDuckGo CAPTCHAs and rate limiting
- Search only discovers files linked on web pages, not full archives
- Pagination issues limit results
- Google/Bing providers don't work reliably

## New Approach

1. **Download complete DOJ archives** (12 datasets, ~340GB)
2. **Multiple download methods**: Direct ZIP, integrated torrent (aria2c), magnet links for external clients
3. **Browse locally** with gallery/grid view, thumbnails, filters
4. **Search as secondary** feature for new documents not yet in archives

## Navigation Structure

| Tab | Purpose |
|-----|---------|
| **Archives** | Download DOJ datasets via ZIP/torrent |
| **Library** | Gallery view of downloaded files |
| **Search** | Secondary - find new documents online |
| **Queue** | Download progress (archives + individual files) |
| **Settings** | App configuration |
| **About** | App info |

**Removed:** MCP, Snapshots

## Archives Page

### Dataset Availability

| Datasets | ZIP | Torrent | Notes |
|----------|-----|---------|-------|
| 1-8, 12 | ✓ | ✓ | Direct download available |
| 9, 10, 11 | ✗ | ✓ | ZIP removed from DOJ, torrent only |

### Download Methods

- **ZIP button**: Direct HTTP download (built-in)
- **Torrent button**: Start via aria2c daemon
- **Magnet link**: Copy to clipboard for external client
- **Auto-extract**: Unzip to Library folder after download

### Magnet Links

```
Dataset 9:  magnet:?xt=urn:btih:0a3d4b84a77bd982c9c2761f40944402b94f9c64
Dataset 10: magnet:?xt=urn:btih:d509cc4ca1a415a9ba3b6cb920f67c44aed7fe1f
```

## Library Page (Gallery View)

### Features

- Thumbnail grid view
- Filters: Dataset (1-12), File type (PDF/Image/Video/Audio), Sort (Name/Size/Date)
- Filename search
- Pagination with configurable grid size (S/M/L)
- Click to open in built-in viewer

### Thumbnails

- **PDFs**: First page rendered
- **Images**: Scaled preview
- **Videos**: First frame or icon
- **Audio**: Waveform icon

### Performance

- Lazy load on scroll
- Background thumbnail generation
- SQLite index for fast filtering

## Technical Architecture

### Storage Structure

```
~/Documents/Zephaniah/
├── archives/           # Downloaded ZIPs (can delete after extract)
├── library/
│   ├── Dataset_01/
│   ├── Dataset_02/
│   └── ...
├── thumbnails/         # Cached thumbnails for gallery
└── database/           # SQLite for file index
```

### Database Schema

```sql
CREATE TABLE archives (
  id TEXT PRIMARY KEY,
  dataset_number INTEGER,
  download_method TEXT,  -- 'zip', 'torrent'
  status TEXT,           -- 'pending', 'downloading', 'extracting', 'complete'
  progress REAL,
  file_path TEXT,
  downloaded_at TIMESTAMP
);

CREATE TABLE library_files (
  id TEXT PRIMARY KEY,
  dataset_number INTEGER,
  filename TEXT,
  file_path TEXT,
  file_type TEXT,        -- 'pdf', 'image', 'video', 'audio', 'other'
  file_size INTEGER,
  thumbnail_path TEXT,
  indexed_at TIMESTAMP
);
```

### aria2c Integration

- Start daemon on app launch: `aria2c --enable-rpc --rpc-listen-port=6800`
- JSON-RPC communication for torrent management
- Monitor progress via polling

## Files to Modify

### Remove

- `lib/pages/mcp_page.dart`
- `lib/pages/snapshots_page.dart`
- `lib/services/mcp_service.dart`
- `lib/services/snapshot_service.dart`

### Modify

- `lib/pages/doj_archives_page.dart` → Add torrent support, magnet links
- `lib/pages/artifacts_page.dart` → Rename to `library_page.dart`, gallery view
- `lib/pages/search_page.dart` → Simplify, DuckDuckGo only
- `lib/pages/queue_page.dart` → Add torrent progress
- `lib/main.dart` → Update navigation
- `lib/widgets/sidebar.dart` → Remove MCP, Snapshots

### Create

- `lib/services/aria2_service.dart` - Torrent daemon management
- `lib/services/library_service.dart` - File scanning, indexing
- `lib/services/thumbnail_service.dart` - Generate thumbnails
- `lib/widgets/file_grid.dart` - Gallery grid component
- `lib/widgets/file_thumbnail.dart` - Individual thumbnail card

## Implementation Phases

### Phase 1: Cleanup & Navigation
- Remove MCP, Snapshots pages and services
- Update sidebar navigation (6 items)
- Rename Artifacts → Library

### Phase 2: Enhanced Archives Page
- aria2c daemon integration
- Torrent download support
- Magnet link copy buttons
- Auto-extract ZIPs after download

### Phase 3: Library Gallery View
- File scanner service
- Thumbnail generation (PDF first page, image resize, video frame)
- Grid view with filters and pagination
- SQLite indexing

### Phase 4: Queue Enhancements
- Torrent progress (seeds, peers, speed)
- Extraction progress
- Unified view for archives + individual downloads

### Phase 5: Search Simplification
- Remove Google/Bing providers
- Simplify UI
- Position as secondary feature

## Dependencies

### New Flutter Packages
- `archive` - ZIP extraction
- `pdf_render` - PDF thumbnail generation (or use existing Syncfusion)

### External Tools
- `aria2c` - Cross-platform download utility with torrent support
  - macOS: `brew install aria2`
  - Windows: Download from aria2 releases
  - Linux: `apt install aria2`
