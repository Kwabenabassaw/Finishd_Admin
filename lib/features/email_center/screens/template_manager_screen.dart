import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:finishd_admin/features/email_center/email_repository.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class TemplateManagerScreen extends StatefulWidget {
  const TemplateManagerScreen({super.key});

  @override
  State<TemplateManagerScreen> createState() => _TemplateManagerScreenState();
}

class _TemplateManagerScreenState extends State<TemplateManagerScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _templates = [];

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    setState(() => _isLoading = true);
    try {
      final repo = context.read<EmailRepository>();
      final res = await repo.getTemplates();
      if (mounted) setState(() {
        _templates = res;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showTemplateEditor([Map<String, dynamic>? template]) {
    final isEdit = template != null;
    String name = template?['name'] ?? '';
    String subject = template?['subject'] ?? '';
    String htmlBody = template?['html_body'] ?? '';

    shadcn.showDialog(
      context: context,
      builder: (ctx) => shadcn.AlertDialog(
        title: Text(isEdit ? 'Edit Template' : 'Create Template'),
        content: SingleChildScrollView(
           child: Column(
             mainAxisSize: MainAxisSize.min,
             children: [
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: name,
                  decoration: const InputDecoration(labelText: 'Template Name', border: OutlineInputBorder()),
                  onChanged: (val) => name = val,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: subject,
                  decoration: const InputDecoration(labelText: 'Subject', border: OutlineInputBorder()),
                  onChanged: (val) => subject = val,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: htmlBody,
                  maxLines: 8,
                  decoration: const InputDecoration(labelText: 'HTML Body', border: OutlineInputBorder()),
                  onChanged: (val) => htmlBody = val,
                ),
             ],
           )
        ),
        actions: [
          shadcn.OutlineButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          shadcn.PrimaryButton(
            onPressed: () async {
               final repo = context.read<EmailRepository>();
               try {
                 if (isEdit) {
                   await repo.updateTemplate(template['id'], {
                     'name': name,
                     'subject': subject,
                     'html_body': htmlBody,
                   });
                 } else {
                   await repo.createTemplate({
                     'name': name,
                     'subject': subject,
                     'html_body': htmlBody,
                   });
                 }
                 if (mounted) {
                   Navigator.pop(ctx);
                   _loadTemplates();
                 }
               } catch (e) {
                 // handle err
               }
            },
            child: Text(isEdit ? 'Save Changes' : 'Create'),
          ),
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: shadcn.CircularProgressIndicator());

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTemplateEditor(),
        label: const Text('New Template'),
        icon: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: _templates.length,
        itemBuilder: (context, index) {
          final t = _templates[index];
          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: ListTile(
              title: Text(t['name'] ?? ''),
              subtitle: Text(t['subject'] ?? ''),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => _showTemplateEditor(t),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      await context.read<EmailRepository>().deleteTemplate(t['id']);
                      _loadTemplates();
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
