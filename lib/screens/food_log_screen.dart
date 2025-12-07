import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import '../models/food_entry.dart';
import '../providers/food_log_provider.dart';
import '../providers/weight_provider.dart';
import '../services/ai_service.dart';
import '../services/nutrition_goal_service.dart';
import '../theme/app_spacing.dart';

class FoodLogScreen extends StatefulWidget {
  const FoodLogScreen({super.key});

  @override
  State<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends State<FoodLogScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Log'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showGoalSettings(context),
            tooltip: 'Nutrition Goals',
          ),
        ],
      ),
      body: Consumer<FoodLogProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Date selector
              _buildDateSelector(context),

              // Daily summary card
              _buildDailySummary(context, provider),

              // Meal list
              Expanded(
                child: _buildMealList(context, provider),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddFoodDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Log Food'),
      ),
    );
  }

  Widget _buildDateSelector(BuildContext context) {
    final theme = Theme.of(context);
    final isToday = _isSameDay(_selectedDate, DateTime.now());

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: () {
              setState(() {
                _selectedDate = _selectedDate.subtract(const Duration(days: 1));
              });
            },
          ),
          TextButton(
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                setState(() => _selectedDate = picked);
              }
            },
            child: Text(
              isToday ? 'Today' : DateFormat('EEE, MMM d').format(_selectedDate),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _isSameDay(_selectedDate, DateTime.now())
                ? null
                : () {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                  },
          ),
        ],
      ),
    );
  }

  Widget _buildDailySummary(BuildContext context, FoodLogProvider provider) {
    final theme = Theme.of(context);
    final summary = provider.summaryForDate(_selectedDate);
    final goal = provider.effectiveGoal;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Calorie progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${summary.totalCalories}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  '/ ${goal.targetCalories} cal',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalSm,
            LinearProgressIndicator(
              value: summary.calorieProgress(goal).clamp(0.0, 1.0),
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
            AppSpacing.gapVerticalMd,

            // Macro breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMacroIndicator(
                  context,
                  'Protein',
                  summary.totalProtein,
                  goal.targetProteinGrams ?? 0,
                  'g',
                  Colors.blue,
                ),
                _buildMacroIndicator(
                  context,
                  'Carbs',
                  summary.totalCarbs,
                  goal.targetCarbsGrams ?? 0,
                  'g',
                  Colors.orange,
                ),
                _buildMacroIndicator(
                  context,
                  'Fat',
                  summary.totalFat,
                  goal.targetFatGrams ?? 0,
                  'g',
                  Colors.purple,
                ),
              ],
            ),

            // Fat breakdown (if goal has fat targets)
            if (goal.hasFatBreakdownTargets ||
                summary.totalSaturatedFat > 0 ||
                summary.totalUnsaturatedFat > 0) ...[
              AppSpacing.gapVerticalMd,
              Divider(color: theme.colorScheme.outlineVariant),
              AppSpacing.gapVerticalSm,
              Text(
                'Fat Breakdown',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              AppSpacing.gapVerticalSm,
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildFatIndicator(
                    context,
                    'Saturated',
                    summary.totalSaturatedFat,
                    goal.maxSaturatedFatGrams,
                    isMax: true,
                    color: Colors.red.shade400,
                  ),
                  _buildFatIndicator(
                    context,
                    'Unsaturated',
                    summary.totalUnsaturatedFat,
                    goal.minUnsaturatedFatGrams,
                    isMax: false,
                    color: Colors.green.shade600,
                  ),
                  _buildFatIndicator(
                    context,
                    'Trans',
                    summary.totalTransFat,
                    goal.maxTransFatGrams,
                    isMax: true,
                    color: Colors.red.shade700,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMacroIndicator(
    BuildContext context,
    String label,
    int current,
    int target,
    String unit,
    Color color,
  ) {
    final theme = Theme.of(context);
    final progress = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: progress,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                color: color,
                strokeWidth: 4,
              ),
            ),
            Text(
              '$current',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        AppSpacing.gapVerticalXs,
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
        if (target > 0)
          Text(
            '/$target$unit',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  /// Build a fat type indicator (saturated, unsaturated, trans)
  /// isMax: true for saturated/trans (want to stay under), false for unsaturated (want to meet minimum)
  Widget _buildFatIndicator(
    BuildContext context,
    String label,
    int current,
    int? target, {
    required bool isMax,
    required Color color,
  }) {
    final theme = Theme.of(context);
    // For max targets: over is bad, for min targets: under is bad
    final hasTarget = target != null && target > 0;
    final isOver = hasTarget && current > target;
    final isUnder = hasTarget && current < target;
    final isWarning = isMax ? isOver : isUnder;

    return Column(
      children: [
        Text(
          '${current}g',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isWarning ? theme.colorScheme.error : color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: color,
          ),
        ),
        if (hasTarget)
          Text(
            isMax ? '≤$target g' : '≥$target g',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontSize: 10,
            ),
          ),
      ],
    );
  }

  Widget _buildMealList(BuildContext context, FoodLogProvider provider) {
    final entries = provider.entriesForDate(_selectedDate);

    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Theme.of(context).colorScheme.outline,
            ),
            AppSpacing.gapVerticalMd,
            Text(
              'No food logged yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            AppSpacing.gapVerticalSm,
            Text(
              'Tap the button below to log your first meal',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    // Sort all entries by time
    final sortedEntries = List<FoodEntry>.from(entries)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
      itemCount: sortedEntries.length,
      itemBuilder: (context, index) {
        return _buildFoodEntryTile(context, sortedEntries[index], provider);
      },
    );
  }

  Widget _buildFoodEntryTile(
    BuildContext context,
    FoodEntry entry,
    FoodLogProvider provider,
  ) {
    final theme = Theme.of(context);
    final timeFormat = DateFormat('h:mm a');

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      confirmDismiss: (_) => _confirmDelete(context, entry.description),
      onDismissed: (_) => provider.deleteEntry(entry.id),
      child: ListTile(
        leading: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(entry.mealType.emoji, style: const TextStyle(fontSize: 18)),
            Text(
              timeFormat.format(entry.timestamp),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                fontSize: 10,
              ),
            ),
          ],
        ),
        title: Text(entry.description),
        subtitle: entry.nutrition != null
            ? Text(
                entry.nutrition!.summary,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            : null,
        trailing: entry.nutrition != null
            ? Text(
                '${entry.nutrition!.calories} cal',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              )
            : null,
        onTap: () => _showEditFoodDialog(context, entry),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context, String description) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "$description"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showAddFoodDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddFoodBottomSheet(
        selectedDate: _selectedDate,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _showEditFoodDialog(BuildContext context, FoodEntry entry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddFoodBottomSheet(
        selectedDate: _selectedDate,
        existingEntry: entry,
        onSaved: () => setState(() {}),
      ),
    );
  }

  void _showGoalSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _GoalSettingsSheet(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

/// Bottom sheet for adding/editing food entries
class _AddFoodBottomSheet extends StatefulWidget {
  final DateTime selectedDate;
  final FoodEntry? existingEntry;
  final VoidCallback? onSaved;

  const _AddFoodBottomSheet({
    required this.selectedDate,
    this.existingEntry,
    this.onSaved,
  });

  @override
  State<_AddFoodBottomSheet> createState() => _AddFoodBottomSheetState();
}

class _AddFoodBottomSheetState extends State<_AddFoodBottomSheet> {
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  MealType _selectedMealType = MealType.lunch;
  NutritionEstimate? _nutrition;
  bool _isEstimating = false;
  String? _estimateError;
  late TimeOfDay _selectedTime;
  String? _imagePath;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _descriptionController.text = widget.existingEntry!.description;
      _selectedMealType = widget.existingEntry!.mealType;
      _nutrition = widget.existingEntry!.nutrition;
      _selectedTime = TimeOfDay.fromDateTime(widget.existingEntry!.timestamp);
      _imagePath = widget.existingEntry!.imagePath;
    } else {
      // Default to current time
      _selectedTime = TimeOfDay.now();
      // Default meal type based on time of day
      final hour = DateTime.now().hour;
      if (hour < 10) {
        _selectedMealType = MealType.breakfast;
      } else if (hour < 14) {
        _selectedMealType = MealType.lunch;
      } else if (hour < 20) {
        _selectedMealType = MealType.dinner;
      } else {
        _selectedMealType = MealType.snack;
      }
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _estimateNutrition() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    final ai = AIService();

    // Check if Claude API key is configured
    if (!ai.hasApiKey()) {
      setState(() {
        _estimateError = 'Claude API key not configured. Go to Settings → AI Settings to add your API key.';
      });
      return;
    }

    setState(() {
      _isEstimating = true;
      _estimateError = null;
    });

    try {
      final estimate = await ai.estimateNutrition(description);

      if (mounted) {
        setState(() {
          _nutrition = estimate;
          _isEstimating = false;
          if (estimate == null) {
            _estimateError = 'Could not estimate nutrition. Try being more specific about the food and portion size.';
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEstimating = false;
          _estimateError = 'Error estimating nutrition: $e';
        });
      }
    }
  }

  /// Analyze the food photo using AI vision to get description and nutrition
  Future<void> _analyzeImage() async {
    if (_imagePath == null) return;

    final ai = AIService();

    // Check if Claude API key is configured
    if (!ai.hasApiKey()) {
      setState(() {
        _estimateError = 'Claude API key not configured. Go to Settings → AI Settings to add your API key.';
      });
      return;
    }

    setState(() {
      _isEstimating = true;
      _estimateError = null;
    });

    try {
      // Read image bytes
      final Uint8List imageBytes;
      if (kIsWeb) {
        // On web, fetch the image from the path
        final response = await http.get(Uri.parse(_imagePath!));
        imageBytes = response.bodyBytes;
      } else {
        // On mobile, read from file
        imageBytes = await File(_imagePath!).readAsBytes();
      }

      final analysis = await ai.analyzeFoodImage(imageBytes);

      if (mounted) {
        if (analysis != null) {
          setState(() {
            // Auto-fill description if empty
            if (_descriptionController.text.trim().isEmpty) {
              _descriptionController.text = analysis.description;
            }
            _nutrition = analysis.nutrition;
            _isEstimating = false;
          });
        } else {
          setState(() {
            _isEstimating = false;
            _estimateError = 'Could not analyze the image. Make sure the food is clearly visible.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isEstimating = false;
          _estimateError = 'Error analyzing image: $e';
        });
      }
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (kIsWeb) {
      // Web doesn't support camera, only gallery
      if (source == ImageSource.camera) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Camera not supported on web')),
        );
        return;
      }
    }

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        // Copy to app's documents directory for persistence
        if (!kIsWeb) {
          final appDir = await getApplicationDocumentsDirectory();
          final foodImagesDir = Directory('${appDir.path}/food_images');
          if (!await foodImagesDir.exists()) {
            await foodImagesDir.create(recursive: true);
          }
          final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedPath = '${foodImagesDir.path}/$fileName';
          await File(image.path).copy(savedPath);
          setState(() => _imagePath = savedPath);
        } else {
          // On web, just use the temporary path
          setState(() => _imagePath = image.path);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imagePath != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _imagePath = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _save() {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    final provider = context.read<FoodLogProvider>();

    // Combine selected date with selected time
    final timestamp = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final entry = FoodEntry(
      id: widget.existingEntry?.id,
      timestamp: timestamp,
      mealType: _selectedMealType,
      description: description,
      nutrition: _nutrition,
      imagePath: _imagePath,
    );

    if (widget.existingEntry != null) {
      provider.updateEntry(entry);
    } else {
      provider.addEntry(entry);
    }

    widget.onSaved?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingEntry != null ? 'Edit Food' : 'Log Food',
                  style: theme.textTheme.titleLarge,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,

            // Meal type selector with label below
            SegmentedButton<MealType>(
              segments: MealType.values
                  .map((type) => ButtonSegment(
                        value: type,
                        label: Text(type.emoji, style: const TextStyle(fontSize: 20)),
                        tooltip: type.displayName,
                      ))
                  .toList(),
              selected: {_selectedMealType},
              onSelectionChanged: (selected) {
                setState(() => _selectedMealType = selected.first);
              },
              showSelectedIcon: false,
            ),
            AppSpacing.gapVerticalSm,
            Text(
              'Meal Type: ${_selectedMealType.displayName}',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            AppSpacing.gapVerticalMd,

            // Photo capture section
            _buildPhotoSection(theme),
            AppSpacing.gapVerticalMd,

            // Time selector
            OutlinedButton.icon(
              onPressed: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _selectedTime,
                );
                if (picked != null) {
                  setState(() => _selectedTime = picked);
                }
              },
              icon: const Icon(Icons.access_time),
              label: Text(
                'Time: ${_selectedTime.format(context)}',
              ),
            ),
            AppSpacing.gapVerticalMd,

            // Food description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'What did you eat?',
                hintText: 'e.g., Grilled chicken salad with ranch dressing',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
            ),
            AppSpacing.gapVerticalMd,

            // AI Estimate button
            FilledButton.tonalIcon(
              onPressed: _isEstimating ? null : _estimateNutrition,
              icon: _isEstimating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isEstimating ? 'Estimating...' : 'Estimate Nutrition with AI'),
            ),

            if (_estimateError != null) ...[
              AppSpacing.gapVerticalSm,
              Text(
                _estimateError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],

            // Nutrition display
            if (_nutrition != null) ...[
              AppSpacing.gapVerticalMd,
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Estimated Nutrition',
                            style: theme.textTheme.titleSmall,
                          ),
                          if (_nutrition!.confidence != null)
                            Chip(
                              label: Text(
                                _nutrition!.confidence!,
                                style: theme.textTheme.bodySmall,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      AppSpacing.gapVerticalSm,
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildNutritionValue('Calories', '${_nutrition!.calories}', 'cal'),
                          _buildNutritionValue('Protein', '${_nutrition!.proteinGrams}', 'g'),
                          _buildNutritionValue('Carbs', '${_nutrition!.carbsGrams}', 'g'),
                          _buildNutritionValue('Fat', '${_nutrition!.fatGrams}', 'g'),
                        ],
                      ),
                      // Fat breakdown row (if available)
                      if (_nutrition!.saturatedFatGrams != null ||
                          _nutrition!.unsaturatedFatGrams != null ||
                          _nutrition!.transFatGrams != null) ...[
                        AppSpacing.gapVerticalSm,
                        Divider(color: theme.colorScheme.outlineVariant),
                        AppSpacing.gapVerticalSm,
                        Text(
                          'Fat Breakdown',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                        AppSpacing.gapVerticalXs,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildNutritionValue(
                              'Saturated',
                              '${_nutrition!.saturatedFatGrams ?? 0}',
                              'g',
                              color: theme.colorScheme.error.withValues(alpha: 0.8),
                            ),
                            _buildNutritionValue(
                              'Unsaturated',
                              '${_nutrition!.unsaturatedFatGrams ?? 0}',
                              'g',
                              color: Colors.green.shade700,
                            ),
                            _buildNutritionValue(
                              'Trans',
                              '${_nutrition!.transFatGrams ?? 0}',
                              'g',
                              color: theme.colorScheme.error,
                            ),
                          ],
                        ),
                      ],
                      if (_nutrition!.notes != null) ...[
                        AppSpacing.gapVerticalSm,
                        Text(
                          _nutrition!.notes!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.outline,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            AppSpacing.gapVerticalLg,

            // Save button
            FilledButton(
              onPressed: _descriptionController.text.trim().isEmpty ? null : _save,
              child: Text(widget.existingEntry != null ? 'Update' : 'Save'),
            ),

            // Safe area padding
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionValue(String label, String value, String unit, {Color? color}) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$label ($unit)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: color ?? theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildPhotoSection(ThemeData theme) {
    if (_imagePath != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: _showImageSourceDialog,
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(
                          _imagePath!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_imagePath!),
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _showImageSourceDialog,
                      iconSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Show "Analyze Photo" button when image is present
          AppSpacing.gapVerticalSm,
          FilledButton.tonalIcon(
            onPressed: _isEstimating ? null : _analyzeImage,
            icon: _isEstimating
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isEstimating ? 'Analyzing...' : 'Analyze Photo with AI'),
          ),
        ],
      );
    }

    return OutlinedButton.icon(
      onPressed: _showImageSourceDialog,
      icon: const Icon(Icons.camera_alt),
      label: const Text('Add Photo'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

/// Bottom sheet for setting nutrition goals
class _GoalSettingsSheet extends StatefulWidget {
  const _GoalSettingsSheet();

  @override
  State<_GoalSettingsSheet> createState() => _GoalSettingsSheetState();
}

class _GoalSettingsSheetState extends State<_GoalSettingsSheet> {
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _healthConcernsController = TextEditingController();

  // Micronutrient controllers
  final _sodiumController = TextEditingController();
  final _sugarController = TextEditingController();
  final _fiberController = TextEditingController();

  String? _activityLevel;
  bool _isGenerating = false;
  bool _showMicronutrients = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<FoodLogProvider>();
    final goal = provider.effectiveGoal;
    _caloriesController.text = goal.targetCalories.toString();
    _proteinController.text = (goal.targetProteinGrams ?? 0).toString();
    _carbsController.text = (goal.targetCarbsGrams ?? 0).toString();
    _fatController.text = (goal.targetFatGrams ?? 0).toString();
    _activityLevel = goal.activityLevel;
    if (goal.healthConcerns != null) {
      _healthConcernsController.text = goal.healthConcerns!;
    }
    // Micronutrients
    if (goal.maxSodiumMg != null) {
      _sodiumController.text = goal.maxSodiumMg.toString();
    }
    if (goal.maxSugarGrams != null) {
      _sugarController.text = goal.maxSugarGrams.toString();
    }
    if (goal.minFiberGrams != null) {
      _fiberController.text = goal.minFiberGrams.toString();
    }
    _showMicronutrients = goal.hasMicronutrientTargets;
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _healthConcernsController.dispose();
    _sodiumController.dispose();
    _sugarController.dispose();
    _fiberController.dispose();
    super.dispose();
  }

  Future<void> _generateWithAI() async {
    setState(() => _isGenerating = true);

    try {
      final weightProvider = context.read<WeightProvider>();
      final nutritionService = NutritionGoalService();

      final profile = NutritionProfile(
        weightKg: weightProvider.latestEntry?.weightInKg,
        heightCm: weightProvider.height,
        gender: weightProvider.gender,
        age: weightProvider.age,
        activityLevel: _activityLevel,
        weightGoal: weightProvider.goal,
        healthConcerns: _healthConcernsController.text.trim().isNotEmpty
            ? _healthConcernsController.text.trim()
            : null,
      );

      final result = await nutritionService.generateNutritionGoals(profile);

      if (!mounted) return;

      if (result.success) {
        final goal = result.goal;
        setState(() {
          _caloriesController.text = goal.targetCalories.toString();
          _proteinController.text = (goal.targetProteinGrams ?? 0).toString();
          _carbsController.text = (goal.targetCarbsGrams ?? 0).toString();
          _fatController.text = (goal.targetFatGrams ?? 0).toString();
          if (goal.maxSodiumMg != null) {
            _sodiumController.text = goal.maxSodiumMg.toString();
            _showMicronutrients = true;
          }
          if (goal.maxSugarGrams != null) {
            _sugarController.text = goal.maxSugarGrams.toString();
            _showMicronutrients = true;
          }
          if (goal.minFiberGrams != null) {
            _fiberController.text = goal.minFiberGrams.toString();
            _showMicronutrients = true;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.reasoning),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.errorMessage ?? 'Failed to generate goals'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _save() {
    final goal = NutritionGoal(
      targetCalories: int.tryParse(_caloriesController.text) ?? 2000,
      targetProteinGrams: int.tryParse(_proteinController.text),
      targetCarbsGrams: int.tryParse(_carbsController.text),
      targetFatGrams: int.tryParse(_fatController.text),
      maxSodiumMg: int.tryParse(_sodiumController.text),
      maxSugarGrams: int.tryParse(_sugarController.text),
      minFiberGrams: int.tryParse(_fiberController.text),
      healthConcerns: _healthConcernsController.text.trim().isNotEmpty
          ? _healthConcernsController.text.trim()
          : null,
      activityLevel: _activityLevel,
    );

    context.read<FoodLogProvider>().setGoal(goal);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nutrition Goals', style: theme.textTheme.titleLarge),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            AppSpacing.gapVerticalMd,

            // AI Assistance section
            Card(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.auto_awesome,
                            size: 20, color: theme.colorScheme.primary),
                        AppSpacing.gapHorizontalSm,
                        Text(
                          'AI-Assisted Goals',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapVerticalSm,
                    TextField(
                      controller: _healthConcernsController,
                      decoration: const InputDecoration(
                        hintText: 'e.g., "lower triglycerides" or "manage blood pressure"',
                        labelText: 'Health Concerns (Optional)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: 2,
                      style: theme.textTheme.bodySmall,
                    ),
                    AppSpacing.gapVerticalSm,
                    DropdownButtonFormField<String>(
                      value: _activityLevel,
                      decoration: const InputDecoration(
                        labelText: 'Activity Level',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'sedentary',
                          child: Text('Sedentary'),
                        ),
                        DropdownMenuItem(
                          value: 'light',
                          child: Text('Light (1-3 days/week)'),
                        ),
                        DropdownMenuItem(
                          value: 'moderate',
                          child: Text('Moderate (3-5 days/week)'),
                        ),
                        DropdownMenuItem(
                          value: 'active',
                          child: Text('Active (6-7 days/week)'),
                        ),
                        DropdownMenuItem(
                          value: 'very_active',
                          child: Text('Very Active'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _activityLevel = value);
                      },
                    ),
                    AppSpacing.gapVerticalSm,
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isGenerating ? null : _generateWithAI,
                        icon: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.auto_awesome, size: 18),
                        label: Text(_isGenerating
                            ? 'Generating...'
                            : 'Generate Goals with AI'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            AppSpacing.gapVerticalLg,

            // Macros section
            Text('Macros', style: theme.textTheme.titleSmall),
            AppSpacing.gapVerticalSm,

            TextField(
              controller: _caloriesController,
              decoration: const InputDecoration(
                labelText: 'Daily Calories',
                suffixText: 'cal',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            AppSpacing.gapVerticalMd,
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _proteinController,
                    decoration: const InputDecoration(
                      labelText: 'Protein',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                AppSpacing.gapHorizontalSm,
                Expanded(
                  child: TextField(
                    controller: _carbsController,
                    decoration: const InputDecoration(
                      labelText: 'Carbs',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                AppSpacing.gapHorizontalSm,
                Expanded(
                  child: TextField(
                    controller: _fatController,
                    decoration: const InputDecoration(
                      labelText: 'Fat',
                      suffixText: 'g',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            AppSpacing.gapVerticalMd,

            // Micronutrients toggle
            InkWell(
              onTap: () => setState(() => _showMicronutrients = !_showMicronutrients),
              child: Row(
                children: [
                  Icon(
                    _showMicronutrients
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                  ),
                  AppSpacing.gapHorizontalSm,
                  Text(
                    'Micronutrients',
                    style: theme.textTheme.titleSmall,
                  ),
                ],
              ),
            ),

            if (_showMicronutrients) ...[
              AppSpacing.gapVerticalSm,
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _sodiumController,
                      decoration: const InputDecoration(
                        labelText: 'Sodium (max)',
                        suffixText: 'mg',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  AppSpacing.gapHorizontalSm,
                  Expanded(
                    child: TextField(
                      controller: _sugarController,
                      decoration: const InputDecoration(
                        labelText: 'Sugar (max)',
                        suffixText: 'g',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  AppSpacing.gapHorizontalSm,
                  Expanded(
                    child: TextField(
                      controller: _fiberController,
                      decoration: const InputDecoration(
                        labelText: 'Fiber (min)',
                        suffixText: 'g',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],

            AppSpacing.gapVerticalLg,
            FilledButton(
              onPressed: _save,
              child: const Text('Save Goals'),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}
