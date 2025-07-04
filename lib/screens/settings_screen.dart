import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/settings_provider.dart';
import '../providers/electrum_provider.dart';
import '../providers/theme_provider.dart';

class SettingsScreen extends StatefulWidget {
  final String? initialError;

  const SettingsScreen({
    super.key,
    this.initialError,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _hostController;
  late TextEditingController _portController;
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<SettingsProvider>().nodeSettings ?? NodeSettings.defaults();
    _hostController = TextEditingController(text: settings.host);
    _portController = TextEditingController(text: settings.port.toString());
    _usernameController = TextEditingController(text: settings.username);
    _passwordController = TextEditingController(text: settings.password);
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final settings = NodeSettings(
        host: _hostController.text,
        port: int.parse(_portController.text),
        username: _usernameController.text,
        password: _passwordController.text,
      );

      await context.read<SettingsProvider>().saveNodeSettings(settings);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.settingsSaved ?? 'Settings saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)?.errorSavingSettings(e.toString()) ?? 'Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final electrumProvider = context.watch<ElectrumProvider>();
    final error = electrumProvider.error ?? widget.initialError;
    final isConnected = electrumProvider.isConnected;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.settings ?? 'Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error != null)
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)?.connectionError ?? 'Connection Error',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (isConnected)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline),
                      SizedBox(width: 8),
                      Text(AppLocalizations.of(context)?.connectedToElectrum ?? 'Connected to Electrum server'),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Theme Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.theme ?? 'Theme',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Consumer<ThemeProvider>(
                      builder: (context, themeProvider, child) {
                        return Column(
                          children: [
                            RadioListTile<ThemeMode>(
                              title: Text(AppLocalizations.of(context)?.system ?? 'System'),
                              value: ThemeMode.system,
                              groupValue: themeProvider.themeMode,
                              onChanged: (ThemeMode? value) {
                                if (value != null) {
                                  themeProvider.setThemeMode(value);
                                }
                              },
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text(AppLocalizations.of(context)?.light ?? 'Light'),
                              value: ThemeMode.light,
                              groupValue: themeProvider.themeMode,
                              onChanged: (ThemeMode? value) {
                                if (value != null) {
                                  themeProvider.setThemeMode(value);
                                }
                              },
                            ),
                            RadioListTile<ThemeMode>(
                              title: Text(AppLocalizations.of(context)?.dark ?? 'Dark'),
                              value: ThemeMode.dark,
                              groupValue: themeProvider.themeMode,
                              onChanged: (ThemeMode? value) {
                                if (value != null) {
                                  themeProvider.setThemeMode(value);
                                }
                              },
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            // Language Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Language / اللغة / Dil',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 16),
                    Consumer<SettingsProvider>(
                      builder: (context, settingsProvider, child) {
                        return Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('English'),
                                    value: 'en',
                                    groupValue: settingsProvider.locale.languageCode,
                                    onChanged: (value) {
                                      if (value != null) {
                                        settingsProvider.setLanguage(value);
                                      }
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('العربية'),
                                    value: 'ar',
                                    groupValue: settingsProvider.locale.languageCode,
                                    onChanged: (value) {
                                      if (value != null) {
                                        settingsProvider.setLanguage(value);
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: RadioListTile<String>(
                                    title: const Text('Türkçe'),
                                    value: 'tr',
                                    groupValue: settingsProvider.locale.languageCode,
                                    onChanged: (value) {
                                      if (value != null) {
                                        settingsProvider.setLanguage(value);
                                      }
                                    },
                                  ),
                                ),
                                Expanded(child: Container()), // Empty space for alignment
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Node Settings Section
            Text(
              AppLocalizations.of(context)?.nodeSettings ?? 'Node Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _hostController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.nodeAddress ?? 'Node Address',
                      hintText: AppLocalizations.of(context)?.nodeAddressHint ?? 'e.g., localhost or http://localhost',
                      helperText: AppLocalizations.of(context)?.nodeAddressHelper ?? 'You can include http:// or https:// in the address',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)?.enterNodeAddress ?? 'Please enter the node address';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _portController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.port ?? 'Port',
                      hintText: AppLocalizations.of(context)?.portHint ?? 'e.g., 19332',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)?.enterPortNumber ?? 'Please enter the port number';
                      }
                      final port = int.tryParse(value);
                      if (port == null || port <= 0 || port > 65535) {
                        return AppLocalizations.of(context)?.enterValidPort ?? 'Please enter a valid port number (1-65535)';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.username ?? 'Username (Optional)',
                      hintText: AppLocalizations.of(context)?.usernameHint ?? 'Leave empty if not required',
                    ),
                    validator: (value) {
                      // Username is optional
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)?.password ?? 'Password (Optional)',
                      hintText: AppLocalizations.of(context)?.passwordHint ?? 'Leave empty if not required',
                    ),
                    obscureText: true,
                    validator: (value) {
                      // Password is optional
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _saveSettings,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppLocalizations.of(context)?.saveSettings ?? 'Save Settings'),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () {
                      final defaults = NodeSettings.defaults();
                      _hostController.text = defaults.host;
                      _portController.text = defaults.port.toString();
                      _usernameController.text = defaults.username;
                      _passwordController.text = defaults.password;
                    },
                    child: Text(AppLocalizations.of(context)?.resetToDefaults ?? 'Reset to Defaults'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
