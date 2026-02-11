/// Dataset model for Epstein Files archives
class Dataset {
  final int number;
  final String name;
  final String? zipUrl;
  final String? magnetUri;
  final int sizeBytes;
  final String description;
  final bool zipAvailable;

  const Dataset({
    required this.number,
    required this.name,
    this.zipUrl,
    this.magnetUri,
    required this.sizeBytes,
    required this.description,
    required this.zipAvailable,
  });

  String get folderName => name.replaceAll(' ', '_');

  String get sizeFormatted {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    if (sizeBytes < 1024 * 1024 * 1024) {
      return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(sizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  bool get isLarge => sizeBytes > 10 * 1024 * 1024 * 1024;
}

/// All available datasets from Archive.org
class Datasets {
  static const String archiveOrgBase = 'https://archive.org/download/Epstein-Data-Sets-So-Far';
  static const String googleDriveUrl = 'https://drive.google.com/drive/folders/18tIY9QEGUZe0q_AFAxoPnnVBCWbqHm2p';

  static final List<Dataset> all = [
    Dataset(
      number: 1,
      name: 'DataSet 1',
      zipUrl: '$archiveOrgBase/DataSet%201.zip',
      magnetUri: null,
      sizeBytes: 2652651520,
      description: 'FBI Vault documents - Part 1',
      zipAvailable: true,
    ),
    Dataset(
      number: 2,
      name: 'DataSet 2',
      zipUrl: '$archiveOrgBase/DataSet%202.zip',
      magnetUri: null,
      sizeBytes: 661431549,
      description: 'FBI Vault documents - Part 2',
      zipAvailable: true,
    ),
    Dataset(
      number: 3,
      name: 'DataSet 3',
      zipUrl: '$archiveOrgBase/DataSet%203.zip',
      magnetUri: null,
      sizeBytes: 628539392,
      description: 'FBI Vault documents - Part 3',
      zipAvailable: true,
    ),
    Dataset(
      number: 4,
      name: 'DataSet 4',
      zipUrl: '$archiveOrgBase/DataSet%204.zip',
      magnetUri: null,
      sizeBytes: 375809638,
      description: 'FBI Vault documents - Part 4',
      zipAvailable: true,
    ),
    Dataset(
      number: 5,
      name: 'DataSet 5',
      zipUrl: '$archiveOrgBase/DataSet%205.zip',
      magnetUri: null,
      sizeBytes: 64486400,
      description: 'FBI Vault documents - Part 5',
      zipAvailable: true,
    ),
    Dataset(
      number: 6,
      name: 'DataSet 6',
      zipUrl: '$archiveOrgBase/DataSet%206.zip',
      magnetUri: null,
      sizeBytes: 55574528,
      description: 'FBI Vault documents - Part 6',
      zipAvailable: true,
    ),
    Dataset(
      number: 7,
      name: 'DataSet 7',
      zipUrl: '$archiveOrgBase/DataSet%207.zip',
      magnetUri: null,
      sizeBytes: 102957056,
      description: 'FBI Vault documents - Part 7',
      zipAvailable: true,
    ),
    Dataset(
      number: 8,
      name: 'DataSet 8',
      zipUrl: '$archiveOrgBase/DataSet%208.zip',
      magnetUri: null,
      sizeBytes: 11455324160,
      description: 'FBI Vault documents - Part 8 (Large)',
      zipAvailable: true,
    ),
    Dataset(
      number: 9,
      name: 'DataSet 9',
      zipUrl: '$archiveOrgBase/DataSet%209.zip',
      magnetUri: 'magnet:?xt=urn:btih:7ac8f771678d19c75a26ea6c14e7d4c003fbf9b6&dn=DataSet9',
      sizeBytes: 103353753600,
      description: 'FBI Vault documents - Part 9',
      zipAvailable: true,
    ),
    Dataset(
      number: 10,
      name: 'DataSet 10',
      zipUrl: '$archiveOrgBase/DataSet%2010.zip',
      magnetUri: 'magnet:?xt=urn:btih:d509cc4ca1a415a9ba3b6cb920f67c44aed7fe1f&dn=DataSet10',
      sizeBytes: 88046829568,
      description: 'FBI Vault documents - Part 10',
      zipAvailable: true,
    ),
    Dataset(
      number: 11,
      name: 'DataSet 11',
      zipUrl: '$archiveOrgBase/DataSet%2011.zip',
      magnetUri: 'magnet:?xt=urn:btih:59975667f8bdd5baf9945b0e2db8a57d52d32957&dn=DataSet11',
      sizeBytes: 29527900160,
      description: 'FBI Vault documents - Part 11',
      zipAvailable: true,
    ),
    Dataset(
      number: 12,
      name: 'DataSet 12',
      zipUrl: '$archiveOrgBase/DataSet%2012.zip',
      magnetUri: null,
      sizeBytes: 119633510,
      description: 'FBI Vault documents - Part 12',
      zipAvailable: true,
    ),
    Dataset(
      number: 13,
      name: 'Structured Dataset',
      zipUrl: null,
      magnetUri: 'magnet:?xt=urn:btih:f5cbe5026b1f86617c520d0a9cd610d6254cbe85&dn=StructuredDataset',
      sizeBytes: 5368709120,
      description: 'Community structured dataset with organized files',
      zipAvailable: false,
    ),
  ];

  static int get totalSize => all.fold(0, (sum, d) => sum + d.sizeBytes);

  static Dataset? getByName(String name) {
    try {
      return all.firstWhere((d) => d.name == name);
    } catch (_) {
      return null;
    }
  }

  static Dataset? getByNumber(int number) {
    try {
      return all.firstWhere((d) => d.number == number);
    } catch (_) {
      return null;
    }
  }
}
