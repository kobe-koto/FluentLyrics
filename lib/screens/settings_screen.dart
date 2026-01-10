import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../services/providers/musixmatch_service.dart';

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
                              _buildMusixmatchSection(),
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

  Widget _buildProviderCard(LyricProviderType type, int index) {
    return Container(
      key: ValueKey(type),
      margin: const EdgeInsets.only(bottom: 12),
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
            color: type == LyricProviderType.lrclib
                ? Colors.blue.withOpacity(0.2)
                : Colors.orange.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              (index + 1).toString(),
              style: TextStyle(
                color: type == LyricProviderType.lrclib
                    ? Colors.blue
                    : Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          type == LyricProviderType.lrclib ? 'LRCLIB' : 'Musixmatch',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        subtitle: Text(
          type == LyricProviderType.lrclib
              ? 'Open-source lyrics database'
              : 'World\'s largest lyrics catalog',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
        ),
        trailing: const Icon(Icons.drag_indicator, color: Colors.white24),
      ),
    );
  }
}
