import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import '../services/services.dart';

/// In-app viewer for library files (PDF, video, audio, images, documents)
class LibraryViewerPage extends StatefulWidget {
  final LibraryFile file;

  const LibraryViewerPage({super.key, required this.file});

  @override
  State<LibraryViewerPage> createState() => _LibraryViewerPageState();
}

class _LibraryViewerPageState extends State<LibraryViewerPage> {
  final LibraryService _library = LibraryService();
  late Player _player;
  late VideoController _videoController;
  bool _isMediaInitialized = false;

  @override
  void initState() {
    super.initState();
    if (widget.file.isAudio || widget.file.isVideo) {
      _initializeMedia();
    }
  }

  Future<void> _initializeMedia() async {
    _player = Player();
    _videoController = VideoController(_player);
    await _player.open(Media(widget.file.path));
    if (mounted) {
      setState(() => _isMediaInitialized = true);
    }
  }

  @override
  void dispose() {
    if (widget.file.isAudio || widget.file.isVideo) {
      _player.dispose();
    }
    super.dispose();
  }

  Future<void> _openExternal() async {
    await _library.openFile(widget.file);
  }

  Future<void> _deleteFile() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${widget.file.filename}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final success = await _library.deleteFile(widget.file);
    if (mounted && success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted ${widget.file.filename}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.file.filename,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open),
            onPressed: () => _library.revealInFinder(widget.file),
            tooltip: 'Reveal in Finder',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openExternal,
            tooltip: 'Open in external app',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _deleteFile,
            tooltip: 'Delete file',
          ),
        ],
      ),
      body: Column(
        children: [
          // Info bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            child: Row(
              children: [
                _InfoChip(
                  icon: Icons.folder,
                  label: widget.file.dataset,
                ),
                const SizedBox(width: 16),
                _InfoChip(
                  icon: Icons.storage,
                  label: widget.file.sizeFormatted,
                ),
                const SizedBox(width: 16),
                _InfoChip(
                  icon: Icons.calendar_today,
                  label: _formatDate(widget.file.modifiedAt),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getFileTypeColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.file.fileType.toUpperCase(),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getFileTypeColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildViewer(),
          ),
        ],
      ),
    );
  }

  Widget _buildViewer() {
    if (widget.file.isPdf) {
      return _buildPdfViewer();
    } else if (widget.file.isVideo) {
      return _buildVideoPlayer();
    } else if (widget.file.isAudio) {
      return _buildAudioPlayer();
    } else if (widget.file.isImage) {
      return _buildImageViewer();
    } else if (widget.file.isDocument) {
      return _buildDocumentViewer();
    } else {
      return _buildUnsupportedViewer();
    }
  }

  Widget _buildPdfViewer() {
    final file = File(widget.file.path);
    if (!file.existsSync()) {
      return _buildFileNotFound();
    }

    return SfPdfViewer.file(
      file,
      canShowScrollHead: true,
      canShowScrollStatus: true,
      enableDoubleTapZooming: true,
      onDocumentLoadFailed: (PdfDocumentLoadFailedDetails details) {
        debugPrint('PDF load failed: ${details.error} - ${details.description}');
      },
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isMediaInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Video(
      controller: _videoController,
      controls: AdaptiveVideoControls,
    );
  }

  Widget _buildAudioPlayer() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (!_isMediaInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album art placeholder
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.audio_file,
                size: 80,
                color: Colors.purple,
              ),
            ),
            const SizedBox(height: 32),
            // Title
            Text(
              widget.file.filename,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              widget.file.dataset,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),
            // Progress
            StreamBuilder<Duration>(
              stream: _player.stream.position,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration = _player.state.duration;
                final progress = duration.inMilliseconds > 0
                    ? position.inMilliseconds / duration.inMilliseconds
                    : 0.0;

                return Column(
                  children: [
                    Slider(
                      value: progress.clamp(0.0, 1.0),
                      onChanged: (value) {
                        final newPosition = Duration(
                          milliseconds: (value * duration.inMilliseconds).round(),
                        );
                        _player.seek(newPosition);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(_formatDuration(position)),
                          Text(_formatDuration(duration)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
            // Controls
            StreamBuilder<bool>(
              stream: _player.stream.playing,
              builder: (context, snapshot) {
                final isPlaying = snapshot.data ?? false;
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.replay_10),
                      onPressed: () {
                        final newPos = _player.state.position - const Duration(seconds: 10);
                        _player.seek(newPos);
                      },
                      iconSize: 32,
                    ),
                    const SizedBox(width: 16),
                    FilledButton(
                      onPressed: () {
                        if (isPlaying) {
                          _player.pause();
                        } else {
                          _player.play();
                        }
                      },
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(64, 64),
                        shape: const CircleBorder(),
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause : Icons.play_arrow,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.forward_10),
                      onPressed: () {
                        final newPos = _player.state.position + const Duration(seconds: 10);
                        _player.seek(newPos);
                      },
                      iconSize: 32,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageViewer() {
    final file = File(widget.file.path);
    if (!file.existsSync()) {
      return _buildFileNotFound();
    }

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4.0,
      child: Center(
        child: Image.file(
          file,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return _buildFileNotFound();
          },
        ),
      ),
    );
  }

  Widget _buildDocumentViewer() {
    final file = File(widget.file.path);
    if (!file.existsSync()) {
      return _buildFileNotFound();
    }

    return FutureBuilder<String>(
      future: file.readAsString(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Failed to load document: ${snapshot.error}'),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _openExternal,
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open in External App'),
                ),
              ],
            ),
          );
        }
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: SelectableText(
            snapshot.data ?? '',
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        );
      },
    );
  }

  Widget _buildUnsupportedViewer() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 64,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Preview not available',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This file type cannot be previewed in-app',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: _openExternal,
            icon: const Icon(Icons.open_in_new),
            label: const Text('Open in External App'),
          ),
        ],
      ),
    );
  }

  Widget _buildFileNotFound() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'File not found',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.file.path,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getFileTypeColor() {
    switch (widget.file.fileType) {
      case 'image':
        return Colors.blue;
      case 'video':
        return Colors.orange;
      case 'audio':
        return Colors.purple;
      case 'pdf':
        return Colors.red;
      case 'document':
      case 'text':
        return Colors.blue;
      case 'spreadsheet':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      final hours = duration.inHours.toString();
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
