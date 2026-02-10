<div align="center">
  <img src="assets/01-search-documents.png" alt="Zephaniah" width="700"/>
  <br><br>

  [![GitHub stars](https://img.shields.io/github/stars/BoltzmannEntropy/Zephaniah?style=social)](https://github.com/BoltzmannEntropy/Zephaniah/stargazers)
  [![GitHub forks](https://img.shields.io/github/forks/BoltzmannEntropy/Zephaniah?style=social)](https://github.com/BoltzmannEntropy/Zephaniah/network/members)
  [![GitHub watchers](https://img.shields.io/github/watchers/BoltzmannEntropy/Zephaniah?style=social)](https://github.com/BoltzmannEntropy/Zephaniah/watchers)

  <br>

  [![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](https://opensource.org/licenses/MIT)
  [![GitHub release](https://img.shields.io/github/v/release/BoltzmannEntropy/Zephaniah)](https://github.com/BoltzmannEntropy/Zephaniah/releases)
  [![GitHub downloads](https://img.shields.io/github/downloads/BoltzmannEntropy/Zephaniah/total)](https://github.com/BoltzmannEntropy/Zephaniah/releases)
  [![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Windows%20%7C%20Linux-blue)](https://github.com/BoltzmannEntropy/Zephaniah)
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)

  <br><br>
  <h1>Jeffrey Epstein Document <i>Discovery & Archive</i></h1>
  <p>Discover and download declassified documents related to the Jeffrey Epstein case.<br>Find files from FBI Vault, DOJ archives, Federal Courts, and other government agencies.</p>
  <br>
  <a href="https://boltzmannentropy.github.io/zephaniah.github.io/"><strong>Get Started</strong></a>&nbsp;&nbsp;&nbsp;·&nbsp;&nbsp;&nbsp;<a href="https://github.com/BoltzmannEntropy/Zephaniah"><strong>View on GitHub</strong></a>&nbsp;&nbsp;&nbsp;·&nbsp;&nbsp;&nbsp;<a href="https://github.com/BoltzmannEntropy/Zephaniah/releases"><strong>Download</strong></a>
  <br><br>
</div>

> **Document Discovery** | **Multi-Agency** | **PDF Viewer** | **Media Player** | **Download Queue**

A desktop application for **macOS, Windows, and Linux** focused on discovering and downloading declassified documents related to the **Jeffrey Epstein case**. The app helps you find and download files from government sources—it does **not** search within document contents. Query multiple agencies simultaneously, filter by file type (PDF, DOC, XLS, media files), and build a local archive of relevant documents.

### Supported Institutions

| Category | Agencies |
|----------|----------|
| **Law Enforcement** | FBI Vault, DEA, US Marshals, ICE, ATF |
| **Justice** | Department of Justice, Federal Courts, Supreme Court, CourtListener |
| **Intelligence** | CIA Reading Room, DNI, NSA |
| **Financial** | SEC, FinCEN, Treasury, IRS |
| **State/Diplomatic** | State Department archives |

![Search Documents](assets/01-search-documents.png)

---

## Features

### Multi-Agency Discovery
Find documents from 15+ government agencies simultaneously from a single interface. Advanced filtering by institution category, time range, and file type.

![Download Queue](assets/02-download-queue.png)

### Parallel Downloads
Download multiple documents simultaneously with real-time progress tracking. Configure up to 10 concurrent downloads with automatic retry on failure.

![Artifacts](assets/03-artifacts.png)

### Document Library
Your downloaded artifacts organized chronologically. Browse with the built-in Syncfusion PDF viewer, play audio/video with the integrated media player, and manage storage with detailed statistics.

![Settings](assets/04-settings.png)

### Fully Customizable
Configure default search terms, file types, download settings, and snapshot scheduling. Control storage location, concurrent downloads, and auto-run preferences.

![Storage](assets/05-storage.png)

---

## Installation

### System Requirements

| Component | Requirement |
|-----------|-------------|
| **OS** | macOS 12+ / Windows 10+ / Linux |
| **CPU** | Apple Silicon (M1/M2/M3/M4) or Intel / AMD x64 |
| **RAM** | 4GB minimum, 8GB+ recommended |
| **Storage** | 1GB for application, varies for downloaded artifacts |
| **Flutter** | 3.x with desktop support |

### Download

Download the latest release for your platform:

| Platform | Download |
|----------|----------|
| **macOS** | [Zephaniah-1.0.0-macos.dmg](https://github.com/BoltzmannEntropy/Zephaniah/releases/latest) |
| **Windows** | Coming soon |
| **Linux** | Coming soon |

### macOS Gatekeeper Notice

Since Zephaniah is not notarized with Apple, macOS may display a warning: *"Zephaniah" cannot be opened because Apple cannot check it for malicious software.*

**To open the app:**

**Option 1: Right-click to Open**
1. Right-click (or Control+click) on `Zephaniah.app`
2. Select **Open** from the context menu
3. Click **Open** in the confirmation dialog

**Option 2: System Settings**
1. Open **System Settings → Privacy & Security**
2. Scroll down to find *"Zephaniah" was blocked from use*
3. Click **Open Anyway**
4. Enter your password if prompted

> **Note:** This warning appears because the app is distributed outside the Mac App Store without a paid Apple Developer certificate. The source code is fully open for inspection.

### Build from Source

```bash
git clone https://github.com/BoltzmannEntropy/Zephaniah.git
cd Zephaniah
./install.sh
```

The installer will:
1. Check system prerequisites
2. Install Flutter dependencies
3. Initialize the SQLite database
4. Build the application

### Manual Build

```bash
git clone https://github.com/BoltzmannEntropy/Zephaniah.git
cd Zephaniah

# Install dependencies
flutter pub get

# Run in development mode
flutter run -d macos

# Build release
flutter build macos --release
```

---

## Usage

### Discovery Interface

The app helps you **find and download** documents from government websites—it does not search within document contents.

1. Enter search terms in the search bar (e.g., "Jeffrey Epstein", "Flight Logs")
2. Select quick tags to refine your query
3. Choose search engine (DuckDuckGo recommended for privacy)
4. Set time range filter (Last month, Last year, All time)
5. Select file types (PDF, DOC, XLS, media)
6. Filter by institution category
7. Click Search to find downloadable files

### Download Queue

- **Concurrent Downloads**: Configure parallel download threads (default: 3)
- **Auto-Retry**: Failed downloads automatically retry (configurable attempts)
- **Progress Tracking**: Real-time download progress with file sizes
- **Queue Management**: Clear completed downloads, cancel active downloads

### Settings

| Setting | Description |
|---------|-------------|
| **Default Search Terms** | Pre-fill search bar on launch |
| **Search Engine** | DuckDuckGo (default), Google, Bing |
| **Time Range** | Default time filter for searches |
| **File Types** | Default document types to include |
| **Concurrent Downloads** | Number of parallel downloads (1-10) |
| **Auto-retry Attempts** | Retry count for failed downloads (1-5) |
| **Download Location** | Local storage path for artifacts |
| **Auto-run Snapshot** | Enable daily automated snapshots |
| **Snapshot Retention** | Days to keep snapshot history |

---

## Architecture

```
Zephaniah/
├── install.sh              # Automated installer
├── pubspec.yaml            # Flutter dependencies
│
├── lib/
│   ├── main.dart           # App entry point
│   ├── screens/
│   │   ├── search_screen.dart      # Document search UI
│   │   ├── artifacts_screen.dart   # Downloaded files browser
│   │   ├── history_screen.dart     # Search history
│   │   ├── snapshots_screen.dart   # Snapshot management
│   │   ├── queue_screen.dart       # Download queue
│   │   ├── settings_screen.dart    # App settings
│   │   └── mcp_screen.dart         # MCP integration
│   ├── services/
│   │   ├── search_service.dart     # Search API integration
│   │   ├── download_service.dart   # Download manager
│   │   └── database_service.dart   # SQLite operations
│   └── widgets/
│       ├── pdf_viewer.dart         # Syncfusion PDF viewer
│       └── media_player.dart       # media_kit player
│
├── macos/                  # macOS platform configuration
├── windows/                # Windows platform configuration
├── linux/                  # Linux platform configuration
│
└── assets/                 # App screenshots and icons
```

---

## Privacy & Legal

Zephaniah searches **publicly available** government documents. All queried sources are official public record repositories:

- FBI Vault (vault.fbi.gov)
- DOJ documents (justice.gov)
- Federal Court records (uscourts.gov, supremecourt.gov)
- CourtListener (courtlistener.com)
- CIA Reading Room (cia.gov)
- SEC filings (sec.gov)
- Treasury documents (treasury.gov)

**No private data is accessed.** The application uses standard search engine APIs to find publicly released documents.

---

## Author

| | |
|---|---|
| **Author** | Shlomo Kashani |
| **Position** | Head of AI at [Qneura](https://qneura.ai/apps.html) |
| **Affiliation** | Johns Hopkins University, Maryland, U.S.A. |

---

## Citation

```bibtex
@software{kashani2026zephaniah,
  title={Zephaniah: Jeffrey Epstein Document Search and Archive},
  author={Kashani, Shlomo},
  year={2026},
  institution={Johns Hopkins University},
  url={https://github.com/BoltzmannEntropy/Zephaniah},
  note={Desktop application for searching and archiving declassified Jeffrey Epstein case documents}
}
```

---

## Star History

<a href="https://star-history.com/#BoltzmannEntropy/Zephaniah&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=BoltzmannEntropy/Zephaniah&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=BoltzmannEntropy/Zephaniah&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=BoltzmannEntropy/Zephaniah&type=Date" />
 </picture>
</a>

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

MIT License - Copyright (c) 2026 Shlomo Kashani

## Acknowledgments

- [Flutter](https://flutter.dev) - Cross-platform UI framework
- [Syncfusion Flutter PDF](https://pub.dev/packages/syncfusion_flutter_pdfviewer) - PDF viewer
- [media_kit](https://pub.dev/packages/media_kit) - Media player
- [SQLite](https://sqlite.org) - Local database
- [DuckDuckGo](https://duckduckgo.com) - Privacy-focused search
