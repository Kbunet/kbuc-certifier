import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ContentFormDialog extends StatefulWidget {
  const ContentFormDialog({super.key});

  @override
  State<ContentFormDialog> createState() => _ContentFormDialogState();
}

class _ContentFormDialogState extends State<ContentFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _ownerController = TextEditingController();
  final _nonceController = TextEditingController(text: '1');
  final _nameController = TextEditingController(text: 'New Content');
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _codeController.dispose();
    _ownerController.dispose();
    _nonceController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Create New Content'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter content name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter content description',
                ),
                maxLines: 2,
              ),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'Enter content code',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a code';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ownerController,
                decoration: const InputDecoration(
                  labelText: 'Owner',
                  hintText: 'Enter owner address (hex)',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter an owner address';
                  }
                  if (!RegExp(r'^[0-9a-fA-F]+$').hasMatch(value)) {
                    return 'Owner must be a hex string';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _nonceController,
                decoration: const InputDecoration(
                  labelText: 'Nonce',
                  hintText: 'Enter nonce value',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a nonce';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              Navigator.of(context).pop({
                'name': _nameController.text,
                'description': _descriptionController.text,
                'code': _codeController.text,
                'owner': _ownerController.text,
                'nonce': int.parse(_nonceController.text),
              });
            }
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
