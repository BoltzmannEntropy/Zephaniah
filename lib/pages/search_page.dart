import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/services.dart';
import '../providers/providers.dart';
import '../widgets/institution_card.dart';
import 'results_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final SearchService _search = SearchService();
  final SnapshotService _snapshot = SnapshotService();
  final SettingsService _settings = SettingsService();

  Set<String> _selectedInstitutions = {};
  Set<FileType> _selectedFileTypes = {FileType.pdf};
  TimeRange _selectedTimeRange = TimeRange.lastWeek;
  SearchEngine _selectedEngine = SearchEngine.duckduckgo;
  String? _filterCategory;
  int _maxResults = 20;
  bool _fullInternetSearch = true; // Default to full internet search

  List<Institution> _allInstitutions = [];
  bool _isSearching = false;

  // File types to display in the UI
  static const List<FileType> _displayFileTypes = [
    FileType.pdf,
    FileType.doc,
    FileType.docx,
    FileType.xls,
    FileType.xlsx,
    FileType.ppt,
    FileType.mp3,
    FileType.mp4,
    FileType.wav,
  ];

  // Predefined search terms with colors
  static const List<_SearchTerm> _searchTerms = [
    _SearchTerm('Jeffrey Epstein', Color(0xFFE53935)),
    _SearchTerm('Ghislaine Maxwell', Color(0xFF8E24AA)),
    _SearchTerm('Epstein Island', Color(0xFF43A047)),
    _SearchTerm('Flight Logs', Color(0xFFFB8C00)),
    _SearchTerm('Little St. James', Color(0xFF039BE5)),
    _SearchTerm('Virgin Islands', Color(0xFF00ACC1)),
    _SearchTerm('Palm Beach', Color(0xFFD81B60)),
    _SearchTerm('Lolita Express', Color(0xFF5E35B1)),
    _SearchTerm('Client List', Color(0xFF7CB342)),
    _SearchTerm('Depositions', Color(0xFFFF7043)),
  ];

  @override
  void initState() {
    super.initState();
    _loadInstitutions();
    _loadDefaults();
    _search.addListener(_onSearchChanged);
    _snapshot.addListener(_onSnapshotChanged);
    _searchController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    _search.removeListener(_onSearchChanged);
    _snapshot.removeListener(_onSnapshotChanged);
    super.dispose();
  }

  void _onSearchChanged() {
    if (mounted) setState(() => _isSearching = _search.isSearching);
  }

  void _onSnapshotChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadInstitutions() async {
    final db = DatabaseService();
    final custom = await db.getCustomInstitutions();
    setState(() {
      _allInstitutions = [...DefaultInstitutions.all, ...custom];
    });
  }

  void _loadDefaults() {
    final settings = _settings.settings;
    _searchController.text = settings.defaultSearchTerms;

    _selectedFileTypes = settings.defaultFileTypes
        .map((e) => FileType.fromExtension(e))
        .whereType<FileType>()
        .toSet();

    _selectedTimeRange = TimeRange.values.firstWhere(
      (t) => t.name == settings.defaultTimeRange,
      orElse: () => TimeRange.lastWeek,
    );

    _selectedEngine = SearchEngine.values.firstWhere(
      (e) => e.code == settings.defaultSearchEngine,
      orElse: () => SearchEngine.duckduckgo,
    );

    _selectedInstitutions = settings.defaultInstitutions.toSet();
  }

  Future<void> _performSearch() async {
    if (_searchController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter search terms')),
      );
      return;
    }

    final query = SearchQuery(
      terms: _searchController.text,
      institutions: _allInstitutions
          .where((i) => _selectedInstitutions.contains(i.id))
          .toList(),
      fileTypes: _selectedFileTypes.toList(),
      timeRange: _selectedTimeRange,
      engine: _selectedEngine,
      maxResults: _maxResults,
      fullInternetSearch: _fullInternetSearch,
    );

    try {
      final results = await _search.search(query);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => ResultsPage(
              results: results,
              query: query,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Search failed: $e')),
        );
      }
    }
  }

  Future<void> _runSnapshot() async {
    try {
      await _snapshot.runDailySnapshot(
        customTerms: _searchController.text.isNotEmpty
            ? _searchController.text
            : null,
        customInstitutions: _selectedInstitutions.isNotEmpty
            ? _allInstitutions
                .where((i) => _selectedInstitutions.contains(i.id))
                .toList()
            : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily snapshot completed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Snapshot failed: $e')),
        );
      }
    }
  }

  SearchQuery _buildCurrentSearchQuery() {
    return SearchQuery(
      terms: _searchController.text.isEmpty ? 'search terms' : _searchController.text,
      institutions: _allInstitutions
          .where((i) => _selectedInstitutions.contains(i.id))
          .toList(),
      fileTypes: _selectedFileTypes.toList(),
      timeRange: _selectedTimeRange,
      engine: _selectedEngine,
      maxResults: _maxResults,
      fullInternetSearch: _fullInternetSearch,
    );
  }

  String _buildCurrentQuery() {
    return _buildCurrentSearchQuery().buildQuery();
  }

  String _buildFullSearchUrl() {
    final query = _buildCurrentSearchQuery();
    final provider = _search.getProviderForEngine(query.engine);
    if (provider == null) return '';
    return provider.buildSearchUrl(query);
  }

  bool _isTermSelected(String term) {
    final currentText = _searchController.text.toLowerCase();
    return currentText.contains(term.toLowerCase());
  }

  void _toggleSearchTerm(String term) {
    final currentText = _searchController.text;

    if (_isTermSelected(term)) {
      // Remove the term (check both quoted and unquoted)
      var newText = currentText
          .replaceAll('"$term"', '')
          .replaceAll(term, '')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      _searchController.text = newText;
    } else {
      // Add the term as-is (user can add quotes manually if they want exact match)
      if (currentText.isEmpty) {
        _searchController.text = term;
      } else {
        _searchController.text = '$currentText $term';
      }
    }
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: _searchController.text.length),
    );
  }

  Widget _buildQueryPreview(ThemeData theme) {
    final queryString = _buildCurrentQuery();
    final fullUrl = _buildFullSearchUrl();
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Query string row
          Row(
            children: [
              Icon(Icons.code, size: 16, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Query: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              Expanded(
                child: SelectableText(
                  queryString,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Full URL row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.link, size: 16, color: colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                'URL: ',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.secondary,
                ),
              ),
              Expanded(
                child: SelectableText(
                  fullUrl,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.copy, size: 16),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: fullUrl));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('URL copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                tooltip: 'Copy URL',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Info chips row
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _InfoChip(
                icon: Icons.search,
                label: _selectedEngine.label,
                color: Colors.blue,
              ),
              _InfoChip(
                icon: Icons.access_time,
                label: _selectedTimeRange.label,
                color: Colors.orange,
              ),
              _InfoChip(
                icon: Icons.description,
                label: '${_selectedFileTypes.length} file types',
                color: Colors.green,
              ),
              _InfoChip(
                icon: _fullInternetSearch ? Icons.public : Icons.business,
                label: _fullInternetSearch
                    ? 'Full Web'
                    : '${_selectedInstitutions.length} sites',
                color: _fullInternetSearch ? Colors.green : Colors.purple,
              ),
              _InfoChip(
                icon: Icons.format_list_numbered,
                label: 'max $_maxResults',
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get unique categories
    final categories = _allInstitutions.map((i) => i.category).toSet().toList();

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title and Snapshot button
              Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 28,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Search Documents',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Daily Snapshot button
                  FilledButton.icon(
                    onPressed: _snapshot.isRunning ? null : _runSnapshot,
                    icon: _snapshot.isRunning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.camera_rounded),
                    label: Text(
                      _snapshot.isRunning
                          ? 'Running Snapshot...'
                          : 'Run Daily Snapshot',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8F00),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Search bar
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Enter search terms...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                      onSubmitted: (_) => _performSearch(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: _isSearching ? null : _performSearch,
                    icon: _isSearching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.search),
                    label: const Text('Search'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Quick search term cards
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _searchTerms.map((term) {
                    final isSelected = _isTermSelected(term.text);
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: InkWell(
                        onTap: () => _toggleSearchTerm(term.text),
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? term.color
                                : term.color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: term.color,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 6),
                                  child: Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              Text(
                                term.text,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : term.color,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              // Filters row
              Wrap(
                spacing: 16,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Full Internet Search toggle
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _fullInternetSearch ? Icons.public : Icons.business,
                        size: 18,
                        color: _fullInternetSearch ? Colors.green : Colors.purple,
                      ),
                      const SizedBox(width: 4),
                      Text(_fullInternetSearch ? 'Full Web' : 'Sites Only'),
                      Switch(
                        value: _fullInternetSearch,
                        onChanged: (v) => setState(() => _fullInternetSearch = v),
                      ),
                    ],
                  ),
                  // Search engine
                  _FilterDropdown<SearchEngine>(
                    label: 'Engine',
                    value: _selectedEngine,
                    items: SearchEngine.values,
                    itemLabel: (e) => e.label,
                    onChanged: (e) => setState(() => _selectedEngine = e!),
                  ),
                  // Time range
                  _FilterDropdown<TimeRange>(
                    label: 'Time',
                    value: _selectedTimeRange,
                    items: TimeRange.values
                        .where((t) => t != TimeRange.custom)
                        .toList(),
                    itemLabel: (t) => t.label,
                    onChanged: (t) => setState(() => _selectedTimeRange = t!),
                  ),
                  // Max results
                  _FilterDropdown<int>(
                    label: 'Results',
                    value: _maxResults,
                    items: const [10, 20, 30, 50, 100],
                    itemLabel: (n) => '$n',
                    onChanged: (n) => setState(() => _maxResults = n!),
                  ),
                  // File types
                  const Text('File types:'),
                  ..._displayFileTypes.map((type) {
                    final isSelected = _selectedFileTypes.contains(type);
                    return FilterChip(
                      label: Text(type.label),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedFileTypes.add(type);
                          } else {
                            _selectedFileTypes.remove(type);
                          }
                        });
                      },
                      visualDensity: VisualDensity.compact,
                    );
                  }),
                ],
              ),
              const SizedBox(height: 12),
              // Search query preview
              _buildQueryPreview(theme),
            ],
          ),
        ),
        const Divider(height: 1),
        // Category filter chips
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          child: Row(
            children: [
              Text(
                'Institutions',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 16),
              FilterChip(
                label: const Text('All'),
                selected: _filterCategory == null,
                onSelected: (_) => setState(() => _filterCategory = null),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: categories.map((cat) {
                      final catColor = _allInstitutions
                          .firstWhere((i) => i.category == cat)
                          .color;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: _filterCategory == cat,
                          onSelected: (_) =>
                              setState(() => _filterCategory = cat),
                          selectedColor: catColor.withValues(alpha: 0.2),
                          checkmarkColor: catColor,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: () => setState(() => _selectedInstitutions.clear()),
                icon: const Icon(Icons.clear_all, size: 18),
                label: const Text('Clear'),
              ),
              Text(
                '${_selectedInstitutions.length} selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        // Institution cards grid
        Expanded(
          child: InstitutionCardsGrid(
            institutions: _allInstitutions,
            selectedIds: _selectedInstitutions,
            onToggle: (inst) {
              setState(() {
                if (_selectedInstitutions.contains(inst.id)) {
                  _selectedInstitutions.remove(inst.id);
                } else {
                  _selectedInstitutions.add(inst.id);
                }
              });
            },
            filterCategory: _filterCategory,
          ),
        ),
      ],
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final void Function(T?) onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$label: '),
        DropdownButton<T>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(itemLabel(item)),
            );
          }).toList(),
          onChanged: onChanged,
          underline: const SizedBox(),
          borderRadius: BorderRadius.circular(8),
        ),
      ],
    );
  }
}

class _SearchTerm {
  final String text;
  final Color color;

  const _SearchTerm(this.text, this.color);
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
