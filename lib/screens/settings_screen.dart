import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../services/providers/musixmatch_service.dart';
import '../providers/lyrics_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final MusixmatchService _musixmatchService = MusixmatchService();
  final TextEditingController _tokenController = TextEditingController();

  List<LyricProviderType> _priority = [];
  bool _isLoading = true;
  bool _isFetchingToken = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final priority = await _settingsService.getPriority();
    final token = await _settingsService.getMusixmatchToken();
    setState(() {
      _priority = priority;
      _tokenController.text = token ?? '';
      _isLoading = false;
    });
  }

  Future<void> _savePriority() async {
    await _settingsService.setPriority(_priority);
    if (mounted) {
      _showSnackBar('Priority updated');
    }
  }

  Future<void> _saveToken() async {
    await _settingsService.setMusixmatchToken(_tokenController.text);
    if (mounted) {
      _showSnackBar('Token saved');
    }
  }

  Future<void> _getNewToken() async {
    setState(() => _isFetchingToken = true);
    try {
      final newToken = await _musixmatchService.fetchNewToken();
      if (newToken != null) {
        setState(() {
          _tokenController.text = newToken;
        });
        await _settingsService.setMusixmatchToken(newToken);
        if (mounted) _showSnackBar('New token acquired');
      } else {
        if (mounted) _showSnackBar('Failed to get new token');
      }
    } finally {
      setState(() => _isFetchingToken = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        backgroundColor: Colors.white24,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF1A1A1A), Colors.black],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAppBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        )
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildPrioritySection(),
                              const SizedBox(height: 48),
                              _buildDisplaySection(),
                              const SizedBox(height: 48),
                              _buildMusixmatchSection(),
                              const SizedBox(height: 48),
                              _buildCacheSection(),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplaySection() {
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DISPLAY CONFIGURATION',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adjust how lyrics are displayed and scrolled.',
              style: TextStyle(color: Colors.white38, fontSize: 14),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lines Before Active',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${provider.linesBefore}',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Number of preceding lines to show when auto-scrolling.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue,
                      inactiveTrackColor: Colors.white10,
                      thumbColor: Colors.blue,
                      overlayColor: Colors.blue.withValues(alpha: 0.2),
                      showValueIndicator: ShowValueIndicator.onDrag,
                      year2023: false,
                    ),
                    child: Slider(
                      value: provider.linesBefore.toDouble(),
                      min: 0,
                      max: 5,
                      divisions: 5,
                      label: provider.linesBefore.toString(),
                      onChanged: (value) {
                        provider.setLinesBefore(value.toInt());
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Global Lyrics Offset',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (provider.globalOffset != Duration.zero)
                            IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                size: 18,
                                color: Colors.blue,
                              ),
                              onPressed: () =>
                                  provider.setGlobalOffset(Duration.zero),
                              tooltip: 'Reset to 0s',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '${(provider.globalOffset.inMilliseconds / 1000.0).toStringAsFixed(1)}s',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Set a default offset for all lyrics (e.g. if your device has audio latency).',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue,
                      inactiveTrackColor: Colors.white10,
                      thumbColor: Colors.blue,
                      overlayColor: Colors.blue.withValues(alpha: 0.2),
                      showValueIndicator: ShowValueIndicator.onDrag,
                      year2023: false,
                    ),
                    child: Slider(
                      value: (provider.globalOffset.inMilliseconds / 100)
                          .toDouble(),
                      min: -50,
                      max: 50,
                      divisions: 100,
                      label: (provider.globalOffset.inMilliseconds / 1000.0)
                          .toStringAsFixed(1),
                      onChanged: (value) {
                        provider.setGlobalOffset(
                          Duration(milliseconds: (value * 100).toInt()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Auto-Resume Delay',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          if (provider.scrollAutoResumeDelay != 5)
                            IconButton(
                              icon: const Icon(
                                Icons.refresh,
                                size: 18,
                                color: Colors.blue,
                              ),
                              onPressed: () =>
                                  provider.setScrollAutoResumeDelay(5),
                              tooltip: 'Reset to 5s',
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          const SizedBox(width: 8),
                          Text(
                            '${provider.scrollAutoResumeDelay}s',
                            style: const TextStyle(
                              color: Colors.blue,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Time to wait before auto-scrolling resumes after you manual scroll.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: Colors.blue,
                      inactiveTrackColor: Colors.white10,
                      thumbColor: Colors.blue,
                      overlayColor: Colors.blue.withValues(alpha: 0.2),
                      showValueIndicator: ShowValueIndicator.always,
                      year2023: false,
                    ),
                    child: Slider(
                      value: provider.scrollAutoResumeDelay.toDouble(),
                      min: 0,
                      max: 30,
                      divisions: 30,
                      label: '${provider.scrollAutoResumeDelay}s',
                      onChanged: (value) {
                        provider.setScrollAutoResumeDelay(value.toInt());
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Blur Effect',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Blur non-active lyric lines for focus.',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    ],
                  ),
                  Switch(
                    value: provider.blurEnabled,
                    activeColor: Colors.blue,
                    activeTrackColor: Colors.blue.withValues(alpha: 0.3),
                    onChanged: (value) => provider.setBlurEnabled(value),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          const Text(
            'Lyrics Configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrioritySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROVIDER PRIORITY',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Reorder providers to prioritize where we fetch lyrics from first.',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
        const SizedBox(height: 24),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final item = _priority.removeAt(oldIndex);
              _priority.insert(newIndex, item);
            });
            _savePriority();
          },
          proxyDecorator: (child, index, animation) {
            return Material(color: Colors.transparent, child: child);
          },
          children: _priority.asMap().entries.map((entry) {
            return _buildProviderCard(entry.value, entry.key);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMusixmatchSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MUSIXMATCH CONFIGURATION',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'The User Token is used to retrieve lyrics from Musixmatch. If you have problems with retrieving lyrics, try get a new one.',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'User Token',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _tokenController,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontFamily: 'monospace',
                ),
                decoration: InputDecoration(
                  hintText: 'Enter your User Token',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.black26,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onChanged: (_) => _saveToken(),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isFetchingToken ? null : _getNewToken,
                      icon: _isFetchingToken
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.orange,
                              ),
                            )
                          : const Icon(Icons.refresh, size: 18),
                      label: const Text('Get New Token'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.withValues(alpha: 0.2),
                        foregroundColor: Colors.orange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  Widget _buildCacheSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CACHE MANAGEMENT',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage local storage for lyrics.',
          style: TextStyle(color: Colors.white38, fontSize: 14),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Consumer<LyricsProvider>(
            builder: (context, provider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Lyrics Cache',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      FutureBuilder<Map<String, dynamic>>(
                        future: provider.getCacheStats(),
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final count = snapshot.data!['count'];
                            final size = snapshot.data!['size'];
                            return Text(
                              '$count items, ${_formatSize(size)}',
                              style: const TextStyle(
                                color: Colors.blue,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Clearing the cache will force the app to search for lyrics again.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: const Color(0xFF1A1A1A),
                                title: const Text(
                                  'Clear Cache',
                                  style: TextStyle(color: Colors.white),
                                ),
                                content: const Text(
                                  'Are you sure you want to clear all cached lyrics?',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: const Text('CANCEL'),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: const Text(
                                      'CLEAR ALL',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              await provider.clearAllCache();
                              setState(() {}); // Refresh the statistics
                              if (mounted) _showSnackBar('Cache cleared');
                            }
                          },
                          icon: const Icon(Icons.delete_sweep, size: 18),
                          label: const Text('Clear All Lyrics Cache'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.2),
                            foregroundColor: Colors.redAccent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(LyricProviderType type, int index) {
    Color color;
    String name;
    String description;

    switch (type) {
      case LyricProviderType.lrclib:
        color = Colors.blue;
        name = 'LRCLIB';
        description = 'Open-source lyrics database';
        break;
      case LyricProviderType.musixmatch:
        color = Colors.orange;
        name = 'Musixmatch';
        description = 'World\'s largest lyrics catalog';
        break;
      case LyricProviderType.netease:
        color = Colors.red;
        name = 'Netease Music';
        description = 'Chinese music service, community driven lyrics catalog';
        break;
    }

    return Container(
      key: ValueKey(type),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ReorderableDragStartListener(
        index: index,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                (index + 1).toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          title: Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            description,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
          trailing: const Icon(Icons.drag_indicator, color: Colors.white24),
        ),
      ),
    );
  }
}
