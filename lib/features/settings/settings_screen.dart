import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/core/admin_repository.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _maintenanceMode = false;
  bool _enableNewFeedAlgo = true;
  bool _autoModEnabled = true;
  double _uploadLimit = 100;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadSettings();
    });
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final repository = context.read<AdminRepository>();
      final settings = await repository.getSettings();
      setState(() {
        _maintenanceMode = (settings['maintenance_mode'] ?? false) as bool;
        _enableNewFeedAlgo = (settings['enable_v2_feed'] ?? true) as bool;
        _autoModEnabled = (settings['auto_moderation_enabled'] ?? true) as bool;
        _uploadLimit = (settings['max_upload_size_mb'] ?? 100.0) as double;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        debugPrint('Error loading settings: $e');
      }
    }
  }

  Future<void> _updateSetting(String key, dynamic value) async {
    try {
      await context.read<AdminRepository>().updateSetting(key, value);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$key updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating setting: $e')));
        // Revert UI on error? For now, we just show error.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Settings',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Feature Flags'),
          SwitchListTile(
            title: const Text('Maintenance Mode'),
            subtitle: const Text('Disable access for all non-admin users'),
            value: _maintenanceMode,
            onChanged: (v) {
              setState(() => _maintenanceMode = v);
              _updateSetting('maintenance_mode', v);
            },
          ),
          SwitchListTile(
            title: const Text('Enable V2 Feed Algorithm'),
            value: _enableNewFeedAlgo,
            onChanged: (v) {
              setState(() => _enableNewFeedAlgo = v);
              _updateSetting('enable_v2_feed', v);
            },
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Content & Media'),
          ListTile(
            title: const Text('Max Video Upload Size (MB)'),
            subtitle: Text('${_uploadLimit.toInt()} MB'),
            trailing: SizedBox(
              width: 200,
              child: Slider(
                min: 50,
                max: 500,
                divisions: 9,
                value: _uploadLimit,
                onChanged: (v) => setState(() => _uploadLimit = v),
                onChangeEnd: (v) => _updateSetting('max_upload_size_mb', v),
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Auto-Moderation'),
            subtitle: const Text('Automatically flag content using AI'),
            value: _autoModEnabled,
            onChanged: (v) {
              setState(() => _autoModEnabled = v);
              _updateSetting('auto_moderation_enabled', v);
            },
          ),
          const SizedBox(height: 24),
          const _SectionHeader(title: 'Notifications'),
          ListTile(
            title: const Text('Email Templates'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {},
          ),
          ListTile(
            title: const Text('Push Notification Config'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
