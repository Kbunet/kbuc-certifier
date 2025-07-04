import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/content_provider.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Portable Content Manager'),
      ),
      body: Consumer<ContentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (provider.error != null)
                  Card(
                    color: Colors.red.shade100,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        provider.error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildContentInfo(provider),
                const SizedBox(height: 16),
                _buildActionButtons(context, provider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContentInfo(ContentProvider provider) {
    if (provider.currentContent == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'No content loaded. Create new content or import existing content to begin.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              provider.currentContent!.name,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(provider.currentContent!.description),
            const SizedBox(height: 8),
            Text(
              'Standard: ${provider.currentContent!.standardName} v${provider.currentContent!.standardVersion}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (provider.currentContent!.standardName == 'W3-Gamified-NFT') ...[
              Text('Code: ${provider.currentContent!.standardData['code']}'),
              Text('Owner: ${provider.currentContent!.standardData['owner']}'),
              Text('Nonce: ${provider.currentContent!.standardData['nonce']}'),
              Text('Image Checksum: ${provider.currentContent!.standardData['imageChecksum']}'),
            ],
            const SizedBox(height: 8),
            Text(
              'Content Hash:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            SelectableText(
              provider.currentContent!.contentHash,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
            const SizedBox(height: 16),
            const Text('Files:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...provider.currentContent!.parts.map((part) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.file_present),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(part.name),
                        Text(
                          'Size: ${(part.size / 1024).toStringAsFixed(2)} KB',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, ContentProvider provider) {
    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      alignment: WrapAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: () => _showCreateDialog(context),
          icon: const Icon(Icons.create_new_folder),
          label: const Text('Create New'),
        ),
        ElevatedButton.icon(
          onPressed: provider.importContent,
          icon: const Icon(Icons.folder_open),
          label: const Text('Import'),
        ),
        if (provider.currentContent != null) ...[
          ElevatedButton.icon(
            onPressed: provider.exportContent,
            icon: const Icon(Icons.save),
            label: const Text('Export'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              final isValid = await provider.verifyContent();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isValid ? 'Content verified successfully!' : 'Content verification failed!',
                    ),
                    backgroundColor: isValid ? Colors.green : Colors.red,
                  ),
                );
              }
            },
            icon: const Icon(Icons.verified),
            label: const Text('Verify'),
          ),
          ElevatedButton.icon(
            onPressed: provider.clearContent,
            icon: const Icon(Icons.clear_all),
            label: const Text('Clear'),
          ),
        ],
      ],
    );
  }

  Future<void> _showCreateDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final codeController = TextEditingController();
    final ownerController = TextEditingController();
    final nonceController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New W3-Gamified-NFT Content'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  hintText: 'Enter content name',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Enter content description',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                decoration: const InputDecoration(
                  labelText: 'Code',
                  hintText: 'Enter NFT code',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ownerController,
                decoration: const InputDecoration(
                  labelText: 'Owner (hex)',
                  hintText: 'Enter owner hash (hex)',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: nonceController,
                decoration: const InputDecoration(
                  labelText: 'Nonce',
                  hintText: 'Enter nonce number',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty ||
                  codeController.text.isEmpty ||
                  ownerController.text.isEmpty ||
                  nonceController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please fill all required fields')),
                );
                return;
              }

              final nonce = int.tryParse(nonceController.text);
              if (nonce == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Nonce must be a valid number')),
                );
                return;
              }

              Navigator.pop(context);
              context.read<ContentProvider>().createNewContent(
                name: nameController.text,
                description: descriptionController.text,
                standardName: 'W3-Gamified-NFT',
                standardData: {
                  'code': codeController.text,
                  'owner': ownerController.text,
                  'nonce': nonce,
                },
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
