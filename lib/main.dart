import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'providers/content_provider.dart';
import 'providers/electrum_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/theme_provider.dart';
import 'services/content_service.dart';
import 'services/electrum_service.dart';
import 'screens/content_list_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/help_screen.dart';
import 'widgets/app_logo.dart';
import 'screens/certificate_batch_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();
  final settingsProvider = SettingsProvider(prefs);
  final themeProvider = ThemeProvider(prefs);
  final electrumProvider = ElectrumProvider();
  
  // Initialize providers
  electrumProvider.initialize(settingsProvider);
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => electrumProvider),
        ChangeNotifierProvider(create: (_) => settingsProvider),
        ChangeNotifierProvider(create: (_) => themeProvider),
        ChangeNotifierProvider(create: (_) => ContentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        final settingsProvider = Provider.of<SettingsProvider>(context, listen: true);
        return MaterialApp(
          title: 'KbucCertifier',
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          themeMode: themeProvider.themeMode,
          locale: settingsProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('ar'), // Arabic
          ],
          home: const HomeScreen(),
        );
      },
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller for the search field
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Show tag filter dialog with highlighted selected tags
  void _showTagFilterDialog(BuildContext context, ContentProvider contentProvider) {
    final availableTags = contentProvider.availableTags;
    final selectedTags = List<String>.from(contentProvider.selectedTags);
    final localizations = AppLocalizations.of(context)!;
  
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(localizations.filterByTags),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(localizations.selectTagsToFilter),
                    const SizedBox(height: 8),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: availableTags.map((tag) {
                            final isSelected = selectedTags.contains(tag);
                            return FilterChip(
                              label: Text(
                                tag,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Colors.white : null,
                                ),
                              ),
                              selected: isSelected,
                              selectedColor: Theme.of(context).colorScheme.primary,
                              checkmarkColor: Colors.white,
                              showCheckmark: true,
                              elevation: isSelected ? 3 : 0,
                              padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                              onSelected: (value) {
                                if (value) {
                                  if (!selectedTags.contains(tag)) {
                                    selectedTags.add(tag);
                                  }
                                } else {
                                  selectedTags.remove(tag);
                                }
                                // Update the dialog UI
                                setState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    contentProvider.clearFilters();
                    Navigator.of(context).pop();
                  },
                  child: Text(localizations.clearAll),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(localizations.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    contentProvider.setSelectedTags(selectedTags);
                    Navigator.of(context).pop();
                  },
                  child: Text(localizations.apply),
                ),
              ],
            );
          },
        );
      },
    );
  }
  
  // Show unified filter popup
  void _showFilterPopup(BuildContext context, ContentProvider provider) {
    final localizations = AppLocalizations.of(context)!;
    final availableTags = provider.availableTags;
    final selectedTags = List<String>.from(provider.selectedTags);
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text(localizations.filterContent),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tag filter logic controls
                  Text(
                    localizations.filterLogic,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // AND/OR toggle
                      ChoiceChip(
                        label: const Text('AND'),
                        selected: provider.useAndFilterLogic,
                        onSelected: (_) {
                          provider.toggleTagFilterLogic();
                          setState(() {});
                        },
                        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ),
                      const SizedBox(width: 4),
                      ChoiceChip(
                        label: const Text('OR'),
                        selected: !provider.useAndFilterLogic,
                        onSelected: (_) {
                          provider.toggleTagFilterLogic();
                          setState(() {});
                        },
                        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      ),
                      const Spacer(),
                      // Unified search toggle
                      Row(
                        children: [
                          Text(
                            localizations.unifiedSearch,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Switch(
                            value: provider.includeContentInTagFilter,
                            onChanged: (_) {
                              provider.toggleIncludeContentInTagFilter();
                              setState(() {});
                            },
                            activeColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const Divider(),
                  
                  // Standard filter
                  Text(
                    localizations.standard,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String?>(
                    value: provider.selectedStandard,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String?>(
                        value: null,
                        child: Text(localizations.allStandards),
                      ),
                      ...provider.availableStandards.map(
                        (standard) => DropdownMenuItem<String?>(
                          value: standard,
                          child: Text(standard),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      provider.setSelectedStandard(value);
                      setState(() {});
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Registered only toggle
                  Row(
                    children: [
                      Text(
                        localizations.showRegisteredOnly,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Spacer(),
                      Switch(
                        value: provider.showRegisteredOnly,
                        onChanged: (value) {
                          provider.setShowRegisteredOnly(value);
                          setState(() {});
                        },
                      ),
                    ],
                  ),
                  
                  const Divider(),
                  
                  // Tags section
                  Text(
                    localizations.filterByTags,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  
                  // Active tags section
                  if (provider.selectedTags.isNotEmpty) ...[  
                    Text(
                      localizations.activeTags,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: provider.selectedTags.map((tag) => Chip(
                        label: Text(tag),
                        onDeleted: () {
                          provider.removeTagFilter(tag);
                          selectedTags.remove(tag);
                          setState(() {});
                        },
                        deleteIconColor: Theme.of(context).colorScheme.onPrimary,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                      )).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Available tags
                  Text(
                    localizations.filterByTags ?? 'Available Tags',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: availableTags.map((tag) {
                      final isSelected = selectedTags.contains(tag);
                      return FilterChip(
                        label: Text(
                          tag,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        checkmarkColor: Colors.white,
                        showCheckmark: true,
                        elevation: isSelected ? 3 : 0,
                        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                        onSelected: (value) {
                          if (value) {
                            if (!selectedTags.contains(tag)) {
                              selectedTags.add(tag);
                            }
                          } else {
                            selectedTags.remove(tag);
                          }
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  provider.clearFilters();
                  Navigator.of(context).pop();
                },
                child: Text(localizations.clearFilters),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localizations.close),
              ),
              ElevatedButton(
                onPressed: () {
                  provider.setSelectedTags(selectedTags);
                  Navigator.of(context).pop();
                },
                child: Text(localizations.apply),
              ),
            ],
          );
        },
      ),
    );
  }
  
  // Show standard filter dialog (legacy - kept for reference)
  void _showFilterDialog(BuildContext context, ContentProvider provider) {
    final localizations = AppLocalizations.of(context)!;
  
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(localizations.filterContent),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(localizations.standard),
            const SizedBox(height: 8),
            DropdownButton<String?>(
              value: provider.selectedStandard,
              isExpanded: true,
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(localizations.allStandards),
                ),
                ...provider.availableStandards.map(
                  (standard) => DropdownMenuItem<String?>(
                    value: standard,
                    child: Text(standard),
                  ),
                ),
              ],
              onChanged: (value) {
                provider.setSelectedStandard(value);
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(localizations.showRegisteredOnly),
                const Spacer(),
                Switch(
                  value: provider.showRegisteredOnly,
                  onChanged: (value) {
                    provider.setShowRegisteredOnly(value);
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              provider.clearFilters();
              Navigator.of(context).pop();
            },
            child: Text(localizations.clearFilters),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(localizations.close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (context, contentProvider, child) {
        return Scaffold(
          appBar: AppBar(
            titleSpacing: 8,
            title: Row(
              children: [
                const AppLogo(),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 40,
                    constraints: const BoxConstraints(maxHeight: 40),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)?.searchHint ?? 'Search certificates...',
                              prefixIcon: const Icon(Icons.search, size: 20),
                              suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      contentProvider.clearSearch();
                                    },
                                  )
                                : null,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surfaceVariant,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                              isDense: true,
                            ),
                            onChanged: contentProvider.setSearchQuery,
                          ),
                        ),
                        // Filter button
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: IconButton(
                            icon: Badge(
                              isLabelVisible: contentProvider.hasActiveFilters,
                              child: const Icon(Icons.filter_list, size: 20),
                            ),
                            onPressed: () => _showFilterPopup(context, contentProvider),
                            tooltip: AppLocalizations.of(context)?.filterContent ?? 'Filter Content',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              // Create Content button
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => contentProvider.createContent(context),
                tooltip: AppLocalizations.of(context)?.createContent ?? 'Create Content',
              ),
              // Import Content button
              IconButton(
                icon: const Icon(Icons.cloud_upload),
                onPressed: () => contentProvider.importContent(),
                tooltip: AppLocalizations.of(context)?.importContent ?? 'Import Content',
              ),
              IconButton(
                icon: const Icon(Icons.upload_file),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const CertificateBatchScreen(),
                    ),
                  );
                },
                tooltip: AppLocalizations.of(context)?.batchImport ?? 'Batch Import',
              ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => contentProvider.refresh(),
                tooltip: AppLocalizations.of(context)?.refresh ?? 'Refresh',
              ),
              // Help button
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const HelpScreen()),
                  );
                },
                tooltip: AppLocalizations.of(context)?.help ?? 'Help',
              ),
              // Settings button
              IconButton(
                icon: const Icon(Icons.settings),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  );
                },
                tooltip: AppLocalizations.of(context)?.settings ?? 'Settings',
              ),
            ],
          ),
          body: const ContentListScreen(),
        );
      },
    );
  }
}
