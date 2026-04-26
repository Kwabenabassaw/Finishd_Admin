import 'package:flutter/material.dart';

class CommunityFormDialog extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onSubmit;

  const CommunityFormDialog({
    super.key,
    this.initialData,
    required this.onSubmit,
  });

  @override
  State<CommunityFormDialog> createState() => _CommunityFormDialogState();
}

class _CommunityFormDialogState extends State<CommunityFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _showIdController;
  late TextEditingController _titleController;
  late TextEditingController _posterPathController;
  
  String _mediaType = 'tv'; // Default to tv
  
  @override
  void initState() {
    super.initState();
    _showIdController = TextEditingController(
      text: widget.initialData?['show_id']?.toString() ?? '',
    );
    _titleController = TextEditingController(
      text: widget.initialData?['title'] ?? '',
    );
    _posterPathController = TextEditingController(
      text: widget.initialData?['poster_path'] ?? '',
    );
    
    if (widget.initialData != null && widget.initialData!['media_type'] != null) {
      _mediaType = widget.initialData!['media_type'];
    }
  }

  @override
  void dispose() {
    _showIdController.dispose();
    _titleController.dispose();
    _posterPathController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onSubmit({
        'show_id': int.tryParse(_showIdController.text),
        'title': _titleController.text.trim(),
        'poster_path': _posterPathController.text.trim().isEmpty ? null : _posterPathController.text.trim(),
        'media_type': _mediaType,
      });
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialData != null;
    final theme = Theme.of(context);
    
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor, width: 1),
          boxShadow: [
             BoxShadow(
               color: Colors.black.withValues(alpha: 0.5),
               blurRadius: 24,
               offset: const Offset(0, 10),
             ),
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Community' : 'New Community',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fill out the community details to create a new hub.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('TMDb ID'),
                      TextFormField(
                        controller: _showIdController,
                        decoration: _inputDecoration(theme, 'e.g. 123456'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Required';
                          if (int.tryParse(value) == null) return 'Must be a valid number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Title'),
                      TextFormField(
                        controller: _titleController,
                        decoration: _inputDecoration(theme, 'Community Name'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Required';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Poster Path', optional: true),
                      TextFormField(
                        controller: _posterPathController,
                        decoration: _inputDecoration(theme, '/path.jpg'),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel('Media Type'),
                      DropdownButtonFormField<String>(
                        value: _mediaType,
                        decoration: _inputDecoration(theme, ''),
                        dropdownColor: theme.colorScheme.surface,
                        items: const [
                          DropdownMenuItem(value: 'movie', child: Text('Movie')),
                          DropdownMenuItem(value: 'tv', child: Text('TV Show')),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _mediaType = value);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: theme.dividerColor, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _submit,
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    ),
                    child: Text(isEditing ? 'Save changes' : 'Create community', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          if (optional)
            const Text(' (Optional)', style: TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(ThemeData theme, String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.4), fontSize: 14),
      filled: true,
      fillColor: theme.colorScheme.onSurface.withValues(alpha: 0.02),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: theme.dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
      ),
    );
  }
}
