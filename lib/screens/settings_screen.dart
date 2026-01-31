import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import '../services/settings_service.dart';
import '../models/lyric_provider_type.dart';
import '../services/providers/musixmatch_service.dart';
import '../providers/lyrics_provider.dart';
import '../widgets/settings_slider_card.dart';
import '../widgets/settings_toggle_card.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  final MusixmatchService _musixmatchService = MusixmatchService();
  final TextEditingController _tokenController = TextEditingController();

  List<LyricProviderType> _allProviders = [];
  int _enabledCount = 0;
  bool _cacheEnabled = true;
  bool _isLoading = true;
  bool _isFetchingToken = false;
  String _version = '';

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
    final allProviders =
        (await _settingsService.getAllProvidersOrdered()).current;
    final enabledCount = (await _settingsService.getEnabledCount()).current;
    final cacheEnabled = (await _settingsService.getCacheEnabled()).current;
    final token = (await _settingsService.getMusixmatchToken()).current;
    final packageInfo = await PackageInfo.fromPlatform();
    setState(() {
      _allProviders = allProviders;
      _enabledCount = enabledCount;
      _cacheEnabled = cacheEnabled;
      _tokenController.text = token ?? '';
      _version = packageInfo.version;
      _isLoading = false;
    });
  }

  Future<void> _savePriority() async {
    await _settingsService.setPriority(_allProviders);
    await _settingsService.setEnabledCount(_enabledCount);
    if (mounted) {
      _showSnackBar('Priority updated');
    }
  }

  Future<void> _toggleCache(bool enabled) async {
    setState(() => _cacheEnabled = enabled);
    await _settingsService.setCacheEnabled(enabled);
    if (mounted) {
      _showSnackBar(enabled ? 'Cache enabled' : 'Cache disabled');
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

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
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
                              _buildLyricConfigurationSection(),
                              const SizedBox(height: 48),
                              _buildCacheSection(),
                              const SizedBox(height: 48),
                              _buildVersionSection(),
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
    final List<Widget> listItems = [];
    for (int i = 0; i < _allProviders.length; i++) {
      if (i == _enabledCount) {
        listItems.add(
          _buildDisabledHeader(key: const ValueKey('disabled_header')),
        );
      }
      listItems.add(
        _buildProviderCard(_allProviders[i], i, isEnabled: i < _enabledCount),
      );
    }
    if (_enabledCount == _allProviders.length) {
      listItems.add(
        _buildDisabledHeader(key: const ValueKey('disabled_header')),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PROVIDER PRIORITY',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Reorder providers to prioritize where we fetch lyrics from first. Drag below "DISABLED AREA" to disable.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 24),
        _buildCacheButton(),
        const SizedBox(height: 16),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) {
            setState(() {
              // ReorderableListView indices correspond to the children list
              // Get current visual list to map indices correctly
              final visualList = [];
              for (int i = 0; i < _allProviders.length; i++) {
                if (i == _enabledCount) visualList.add('HEADER');
                visualList.add(_allProviders[i]);
              }
              if (_enabledCount == _allProviders.length) {
                visualList.add('HEADER');
              }

              final item = visualList.removeAt(oldIndex);
              if (newIndex > oldIndex) newIndex--;
              visualList.insert(newIndex, item);

              // Now reconstruct _allProviders and _enabledCount from visualList
              final newAllProviders = <LyricProviderType>[];
              int newEnabledCount = 0;
              bool foundHeader = false;
              for (final v in visualList) {
                if (v == 'HEADER') {
                  foundHeader = true;
                } else {
                  newAllProviders.add(v as LyricProviderType);
                  if (!foundHeader) newEnabledCount++;
                }
              }

              _allProviders = newAllProviders;
              _enabledCount = newEnabledCount;
            });
            _savePriority();
          },
          proxyDecorator: (child, index, animation) {
            return Material(color: Colors.transparent, child: child);
          },
          children: listItems,
        ),
      ],
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
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adjust how lyrics are displayed.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: 'Font Size',
              subtitle: 'Size of the lyric text in pixels.',
              value: provider.fontSize.current,
              min: 12,
              max: 64,
              divisions: 52,
              label: provider.fontSize.current.toInt().toString(),
              valueText: '${provider.fontSize.current.toInt()}',
              onChanged: (value) => provider.setFontSize(value),
              onReset: provider.fontSize.changed
                  ? () => provider.setFontSize(provider.fontSize.defaultValue)
                  : null,
              resetTooltip: 'Reset to 36px',
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: 'Inactive Line Scale',
              subtitle: 'Scale factor for non-highlighted lines.',
              value: provider.inactiveScale.current,
              min: 0.5,
              max: 1.0,
              divisions: 50,
              label: '${(provider.inactiveScale.current * 100).toInt()}%',
              valueText: '${(provider.inactiveScale.current * 100).toInt()}%',
              onChanged: (value) => provider.setInactiveScale(value),
              onReset: provider.inactiveScale.changed
                  ? () => provider.setInactiveScale(
                      provider.inactiveScale.defaultValue,
                    )
                  : null,
              resetTooltip: 'Reset to 85%',
            ),
            const SizedBox(height: 24),
            SettingsToggleCard(
              title: 'Blur Effect',
              subtitle: 'Blur non-active lyric lines for focus.',
              value: provider.blurEnabled.current,
              onChanged: (value) => provider.setBlurEnabled(value),
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: 'Lines Before Active',
              subtitle:
                  'Number of preceding lines to show when auto-scrolling.',
              value: provider.linesBefore.current.toDouble(),
              min: 0,
              max: 5,
              divisions: 5,
              label: provider.linesBefore.current.toString(),
              valueText: '${provider.linesBefore.current}',
              onChanged: (value) => provider.setLinesBefore(value.toInt()),
              onReset: provider.linesBefore.changed
                  ? () => provider.setLinesBefore(
                      provider.linesBefore.defaultValue,
                    )
                  : null,
              resetTooltip: 'Reset to 2',
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: 'Auto-Resume Delay',
              subtitle:
                  'Time to wait before auto-scrolling resumes after you manual scroll.',
              value: provider.scrollAutoResumeDelay.current.toDouble(),
              min: 0,
              max: 30,
              divisions: 30,
              label: '${provider.scrollAutoResumeDelay.current}s',
              valueText: '${provider.scrollAutoResumeDelay.current}s',
              onChanged: (value) =>
                  provider.setScrollAutoResumeDelay(value.toInt()),
              onReset: provider.scrollAutoResumeDelay.changed
                  ? () => provider.setScrollAutoResumeDelay(
                      provider.scrollAutoResumeDelay.defaultValue,
                    )
                  : null,
              resetTooltip: 'Reset to 5s',
            ),
          ],
        );
      },
    );
  }

  Widget _buildLyricConfigurationSection() {
    return Consumer<LyricsProvider>(
      builder: (context, provider, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'LYRIC CONFIGURATION',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Configure how lyrics are fetched and processed.',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SettingsToggleCard(
              title: 'Rich Sync',
              subtitle: 'Enable word-level synchronization.',
              value: provider.richSyncEnabled.current,
              onChanged: (value) => provider.setRichSyncEnabled(value),
            ),
            const SizedBox(height: 24),
            SettingsSliderCard(
              title: 'Global Lyrics Offset',
              subtitle:
                  'Set a default offset for all lyrics (e.g. if your device has audio latency).',
              value: (provider.globalOffset.inMilliseconds / 100).toDouble(),
              min: -50,
              max: 50,
              divisions: 100,
              label: (provider.globalOffset.inMilliseconds / 1000.0)
                  .toStringAsFixed(1),
              valueText:
                  '${(provider.globalOffset.inMilliseconds / 1000.0).toStringAsFixed(1)}s',
              onChanged: (value) {
                provider.setGlobalOffset(
                  Duration(milliseconds: (value * 100).toInt()),
                );
              },
              onReset: provider.globalOffsetSetting.changed
                  ? () => provider.setGlobalOffset(Duration.zero)
                  : null,
              resetTooltip: 'Reset to 0s',
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
                    'Trim Metadata Lines',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Attempt to remove staff/metadata lines from selected providers.',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: LyricProviderType.values
                        .where((v) => v != LyricProviderType.cache)
                        .map((providerType) {
                          final isSelected = provider
                              .trimMetadataProviders
                              .current
                              .contains(providerType);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: GestureDetector(
                              onTap: () {
                                final updated = List<LyricProviderType>.from(
                                  provider.trimMetadataProviders.current,
                                );
                                if (isSelected) {
                                  updated.remove(providerType);
                                } else {
                                  updated.add(providerType);
                                }
                                provider.setTrimMetadataProviders(updated);
                              },
                              child: Row(
                                children: [
                                  Checkbox(
                                    value: isSelected,
                                    onChanged: (value) {
                                      final updated =
                                          List<LyricProviderType>.from(
                                            provider
                                                .trimMetadataProviders
                                                .current,
                                          );
                                      if (value == true) {
                                        updated.add(providerType);
                                      } else {
                                        updated.remove(providerType);
                                      }
                                      provider.setTrimMetadataProviders(
                                        updated,
                                      );
                                    },
                                    activeColor: Colors.blue,
                                    checkColor: Colors.black,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    providerType.name[0].toUpperCase() +
                                        providerType.name.substring(1),
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        })
                        .toList(),
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
                  const Text(
                    'Musixmatch Token',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Required for Musixmatch provider.',
                    style: TextStyle(color: Colors.white38, fontSize: 12),
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
                          label: const Text(
                            'Get New Token',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.withValues(
                              alpha: 0.2,
                            ),
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
      },
    );
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
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Manage local storage for lyrics.',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 14,
            fontWeight: FontWeight.w500,
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
                          label: const Text(
                            'Clear All Lyrics Cache',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
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

  Widget _buildVersionSection() {
    final versionDisplay = kDebugMode
        ? '(dev, parent v$_version)'
        : 'v$_version';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          'Fluent Lyrics $versionDisplay',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.3),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildCacheButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.storage, color: Colors.grey),
        ),
        title: const Text(
          'Lyrics Cache',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        subtitle: const Text(
          'Always prioritized if enabled',
          style: TextStyle(color: Colors.white38, fontSize: 12),
        ),
        trailing: Switch(
          value: _cacheEnabled,
          onChanged: _toggleCache,
          activeThumbColor: Colors.blue,
        ),
      ),
    );
  }

  Widget _buildDisabledHeader({required Key key}) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Row(
            children: [
              Expanded(child: Divider(color: Colors.white10)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'DISABLED AREA',
                  style: TextStyle(
                    color: Colors.white24,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(child: Divider(color: Colors.white10)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProviderCard(
    LyricProviderType type,
    int index, {
    bool isEnabled = true,
  }) {
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
      case LyricProviderType.qqmusic:
        color = Colors.green;
        name = 'QQ Music';
        description = 'Chinese music streaming service by Tencent';
        break;
      case LyricProviderType.cache:
        color = Colors.grey;
        name = 'Cache';
        description = 'Cached lyrics';
        break;
    }

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.4,
      key: ValueKey(type),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: ReorderableDragStartListener(
          index: index + (index >= _enabledCount ? 1 : 0),
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
                child: isEnabled
                    ? Text(
                        (index + 1).toString(),
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : Icon(
                        Icons.block,
                        size: 20,
                        color: color.withValues(alpha: 0.5),
                      ),
              ),
            ),
            title: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            subtitle: Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: const Icon(Icons.drag_indicator, color: Colors.white24),
          ),
        ),
      ),
    );
  }
}
