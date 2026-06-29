import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/features/email_center/email_repository.dart';
import 'package:finishd_admin/core/admin_repository.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class ComposeEmailScreen extends StatefulWidget {
  const ComposeEmailScreen({super.key});

  @override
  State<ComposeEmailScreen> createState() => _ComposeEmailScreenState();
}

class _ComposeEmailScreenState extends State<ComposeEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  String _target = 'all'; // all, moderators, specific
  String _specificUser = '';
  String _subject = '';
  String _htmlBody = '';
  String? _selectedTemplateId;
  bool _isSending = false;

  List<Map<String, dynamic>> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final repo = context.read<EmailRepository>();
    final templates = await repo.getTemplates();
    if (mounted) {
      setState(() => _templates = templates);
    }
  }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    // Warn before sending to all
    if (_target == 'all') {
      final confirm = await shadcn.showDialog<bool>(
        context: context,
        builder: (ctx) => shadcn.AlertDialog(
          title: const Text('Confirm Mass Email'),
          content: const Text('Are you sure you want to queue this email to ALL users?'),
          actions: [
            shadcn.OutlineButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            shadcn.PrimaryButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, Queue Email'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    setState(() => _isSending = true);
    try {
      final repo = context.read<EmailRepository>();
      final targetVal = _target == 'specific' ? _specificUser : _target;
      
      await repo.sendEmail(
        target: targetVal,
        subject: _subject,
        htmlBody: _htmlBody,
        templateId: _selectedTemplateId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email has been queued.')),
        );
        _formKey.currentState!.reset();
        setState(() {
          _target = 'all';
          _selectedTemplateId = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Compose Email', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 24),
            
            // Target Selection
            Text('Recipient', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTargetOption('all', 'All Users'),
                const SizedBox(width: 16),
                _buildTargetOption('moderators', 'Moderators'),
                const SizedBox(width: 16),
                _buildTargetOption('specific', 'Specific User (ID or Email)'),
              ],
            ),
            if (_target == 'specific') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'User ID or Email',
                        border: OutlineInputBorder(),
                      ),
                      controller: TextEditingController(text: _specificUser),
                      validator: (val) => val == null || val.isEmpty ? 'Required' : null,
                      onChanged: (val) => _specificUser = val,
                      onSaved: (val) => _specificUser = val ?? '',
                    ),
                  ),
                  const SizedBox(width: 16),
                  shadcn.OutlineButton(
                    onPressed: _showUserSearchDialog,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search, size: 16),
                        SizedBox(width: 8),
                        Text('Search User'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            
            // Template Selection
            Text('Template (Optional)', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              value: _selectedTemplateId,
              decoration: const InputDecoration(border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('None (Blank Email)')),
                ..._templates.map((t) => DropdownMenuItem(
                  value: t['id'],
                  child: Text(t['name']),
                ))
              ],
              onChanged: (val) => setState(() => _selectedTemplateId = val),
            ),
            const SizedBox(height: 24),
            
            // Subject
            TextFormField(
              decoration: const InputDecoration(
                labelText: 'Subject',
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (_selectedTemplateId != null) return null; // allow empty if template has subject
                return val == null || val.isEmpty ? 'Subject is required' : null;
              },
              onSaved: (val) => _subject = val ?? '',
            ),
            const SizedBox(height: 24),
            
            // Body
            TextFormField(
              maxLines: 15,
              decoration: const InputDecoration(
                labelText: 'HTML Body',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (_selectedTemplateId != null) return null; 
                return val == null || val.isEmpty ? 'Body is required' : null;
              },
              onSaved: (val) => _htmlBody = val ?? '',
            ),
            const SizedBox(height: 32),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                shadcn.PrimaryButton(
                  onPressed: _isSending ? null : _send,
                  child: _isSending ? const shadcn.CircularProgressIndicator() : const Text('Queue Email'),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTargetOption(String value, String label) {
    return InkWell(
      onTap: () => setState(() => _target = value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Radio<String>(
            value: value,
            groupValue: _target,
            onChanged: (val) => setState(() => _target = val!),
          ),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _showUserSearchDialog() async {
    String searchQuery = '';
    List<Map<String, dynamic>> results = [];
    bool isSearching = false;

    await shadcn.showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return shadcn.AlertDialog(
            title: const Text('Search Users'),
            content: SizedBox(
              width: 500,
              height: 400,
              child: Column(
                children: [
                  TextFormField(
                    decoration: const InputDecoration(
                      hintText: 'Search by username or email...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onFieldSubmitted: (val) async {
                      if (val.isEmpty) return;
                      setDialogState(() => isSearching = true);
                      try {
                        final repo = context.read<AdminRepository>();
                        final users = await repo.getUsers(search: val, limit: 10);
                        setDialogState(() {
                          results = users;
                          isSearching = false;
                        });
                      } catch (e) {
                        setDialogState(() => isSearching = false);
                      }
                    },
                    onChanged: (val) => searchQuery = val,
                  ),
                  const SizedBox(height: 16),
                  if (isSearching)
                    const Expanded(child: Center(child: shadcn.CircularProgressIndicator()))
                  else if (results.isEmpty)
                    const Expanded(child: Center(child: Text('No users found.')))
                  else
                    Expanded(
                      child: ListView.builder(
                        itemCount: results.length,
                        itemBuilder: (ctx, index) {
                          final user = results[index];
                          // Some records might use auth logic, wait getAdminUsers returns what?
                          // Typically it returns profiles with emails joined, or just profiles.
                          // Let's use email if available, else username/id.
                          final email = user['email'] ?? user['id'];
                          final displayName = user['display_name'] ?? user['username'] ?? 'Unknown';
                          
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                              child: user['avatar_url'] == null ? const Icon(Icons.person) : null,
                            ),
                            title: Text(displayName),
                            subtitle: Text(email),
                            onTap: () {
                              setState(() {
                                _specificUser = email;
                              });
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    )
                ],
              ),
            ),
            actions: [
              shadcn.OutlineButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          );
        }
      ),
    );
  }
}
