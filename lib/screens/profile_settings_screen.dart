// lib/screens/profile_settings_screen.dart
// Screen for managing user profile settings

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../providers/weight_provider.dart';
import '../theme/app_spacing.dart';
import '../constants/app_strings.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _storage = StorageService();
  final _nameController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String _userName = '';

  // Height fields
  bool _useMetricHeight = true;
  final _heightCmController = TextEditingController();
  final _heightFeetController = TextEditingController();
  final _heightInchesController = TextEditingController();

  // Gender
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightCmController.dispose();
    _heightFeetController.dispose();
    _heightInchesController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    final settings = await _storage.loadSettings();
    final name = settings['userName'] as String?;

    if (name != null) {
      _userName = name;
      _nameController.text = name;
    }

    // Load height and gender from weight provider
    if (!mounted) return;
    final weightProvider = context.read<WeightProvider>();
    final heightCm = weightProvider.height;
    final gender = weightProvider.gender;

    if (heightCm != null) {
      _heightCmController.text = heightCm.toStringAsFixed(0);
      // Also populate imperial fields
      final totalInches = heightCm / 2.54;
      final feet = (totalInches / 12).floor();
      final inches = (totalInches % 12).round();
      _heightFeetController.text = feet.toString();
      _heightInchesController.text = inches.toString();
    }

    _selectedGender = gender;

    setState(() => _isLoading = false);
  }

  Future<void> _saveName() async {
    final newName = _nameController.text.trim();

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(AppStrings.pleaseEnterYourName),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (newName == _userName) {
      // No change
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Save to storage
      final settings = await _storage.loadSettings();
      settings['userName'] = newName;
      await _storage.saveSettings(settings);

      setState(() {
        _userName = newName;
        _isSaving = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(AppStrings.nameUpdatedSuccessfully),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() => _isSaving = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveHeight() async {
    double? heightCm;

    if (_useMetricHeight) {
      heightCm = double.tryParse(_heightCmController.text);
    } else {
      final feet = int.tryParse(_heightFeetController.text) ?? 0;
      final inches = int.tryParse(_heightInchesController.text) ?? 0;
      if (feet > 0 || inches > 0) {
        heightCm = (feet * 12 + inches) * 2.54;
      }
    }

    if (heightCm != null && heightCm > 50 && heightCm < 300) {
      final weightProvider = context.read<WeightProvider>();
      await weightProvider.setHeight(heightCm);

      // Update the other unit's fields
      if (_useMetricHeight) {
        final totalInches = heightCm / 2.54;
        final feet = (totalInches / 12).floor();
        final inches = (totalInches % 12).round();
        _heightFeetController.text = feet.toString();
        _heightInchesController.text = inches.toString();
      } else {
        _heightCmController.text = heightCm.toStringAsFixed(0);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Height saved'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } else if (heightCm != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid height'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveGender(String? gender) async {
    final weightProvider = context.read<WeightProvider>();
    await weightProvider.setGender(gender);
    setState(() {
      _selectedGender = gender;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.profile),
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          // Header info
          Card(
            child: Padding(
              padding: AppSpacing.paddingLg,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  AppSpacing.gapHorizontalMd,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Your Profile',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        AppSpacing.gapSm,
                        Text(
                          'Manage your personal information and preferences.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.gapXl,

          // Name Section
          Text(
            AppStrings.yourName,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            'This name is used throughout the app to personalize your experience',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          AppSpacing.gapLg,

          // Name input field
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              labelText: AppStrings.yourName,
              hintText: 'Enter your first name',
              prefixIcon: Icon(Icons.badge),
            ),
            textCapitalization: TextCapitalization.words,
            onChanged: (_) {
              // Auto-save on change with debounce could be added here
            },
          ),

          AppSpacing.gapLg,

          // Save button
          FilledButton.icon(
            onPressed: _isSaving ? null : _saveName,
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_isSaving ? '${AppStrings.save}...' : AppStrings.saveChanges),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          AppSpacing.gapXl,

          const Divider(),

          AppSpacing.gapXl,

          // Gender Section
          Text(
            'Gender',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            'Used for more accurate health calculations (BMR, calorie needs)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          AppSpacing.gapLg,

          // Gender selection
          SegmentedButton<String?>(
            segments: const [
              ButtonSegment<String?>(
                value: 'male',
                label: Text('Male'),
                icon: Icon(Icons.male),
              ),
              ButtonSegment<String?>(
                value: 'female',
                label: Text('Female'),
                icon: Icon(Icons.female),
              ),
              ButtonSegment<String?>(
                value: null,
                label: Text('Prefer not to say'),
              ),
            ],
            selected: {_selectedGender},
            onSelectionChanged: (Set<String?> selection) {
              _saveGender(selection.first);
            },
          ),

          AppSpacing.gapXl,

          const Divider(),

          AppSpacing.gapXl,

          // Height Section
          Text(
            'Height',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          AppSpacing.gapMd,
          Text(
            'Used for BMI calculation and health metrics',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
          AppSpacing.gapLg,

          // Unit toggle
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment<bool>(
                value: true,
                label: Text('cm'),
              ),
              ButtonSegment<bool>(
                value: false,
                label: Text('ft/in'),
              ),
            ],
            selected: {_useMetricHeight},
            onSelectionChanged: (Set<bool> selection) {
              setState(() {
                _useMetricHeight = selection.first;
              });
            },
          ),

          AppSpacing.gapLg,

          // Height input
          if (_useMetricHeight)
            TextField(
              controller: _heightCmController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Height (cm)',
                hintText: 'e.g., 175',
                prefixIcon: Icon(Icons.height),
                suffixText: 'cm',
              ),
              keyboardType: TextInputType.number,
              onSubmitted: (_) => _saveHeight(),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _heightFeetController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Feet',
                      hintText: '5',
                      suffixText: 'ft',
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _saveHeight(),
                  ),
                ),
                AppSpacing.gapHorizontalMd,
                Expanded(
                  child: TextField(
                    controller: _heightInchesController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Inches',
                      hintText: '10',
                      suffixText: 'in',
                    ),
                    keyboardType: TextInputType.number,
                    onSubmitted: (_) => _saveHeight(),
                  ),
                ),
              ],
            ),

          AppSpacing.gapLg,

          // Save height button
          OutlinedButton.icon(
            onPressed: _saveHeight,
            icon: const Icon(Icons.save),
            label: const Text('Save Height'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              minimumSize: const Size(double.infinity, 56),
            ),
          ),

          // Extra bottom padding for nav bar
          const SizedBox(height: 100),
        ],
      ),
    );
  }
}
