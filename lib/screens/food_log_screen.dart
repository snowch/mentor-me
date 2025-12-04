import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/food_entry.dart';
import '../providers/food_log_provider.dart';
import '../services/ai_service.dart';
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

  Widget _buildMealList(BuildContext context, FoodLogProvider provider) {
    final entries = provider.entriesForDate(_selectedDate);
    final byMealType = provider.entriesByMealType(_selectedDate);

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

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100), // Space for FAB
      itemCount: MealType.values.length,
      itemBuilder: (context, index) {
        final mealType = MealType.values[index];
        final mealEntries = byMealType[mealType] ?? [];

        if (mealEntries.isEmpty) return const SizedBox.shrink();

        return _buildMealSection(context, mealType, mealEntries, provider);
      },
    );
  }

  Widget _buildMealSection(
    BuildContext context,
    MealType mealType,
    List<FoodEntry> entries,
    FoodLogProvider provider,
  ) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(mealType.emoji, style: const TextStyle(fontSize: 20)),
              AppSpacing.gapHorizontalSm,
              Text(
                mealType.displayName,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        ...entries.map((entry) => _buildFoodEntryTile(context, entry, provider)),
      ],
    );
  }

  Widget _buildFoodEntryTile(
    BuildContext context,
    FoodEntry entry,
    FoodLogProvider provider,
  ) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      onDismissed: (_) => provider.deleteEntry(entry.id),
      child: ListTile(
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
  MealType _selectedMealType = MealType.lunch;
  NutritionEstimate? _nutrition;
  bool _isEstimating = false;
  String? _estimateError;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _descriptionController.text = widget.existingEntry!.description;
      _selectedMealType = widget.existingEntry!.mealType;
      _nutrition = widget.existingEntry!.nutrition;
    } else {
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

    setState(() {
      _isEstimating = true;
      _estimateError = null;
    });

    try {
      final ai = AIService();
      final estimate = await ai.estimateNutrition(description);

      if (mounted) {
        setState(() {
          _nutrition = estimate;
          _isEstimating = false;
          if (estimate == null) {
            _estimateError = 'Could not estimate nutrition. Try being more specific.';
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

  void _save() {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    final provider = context.read<FoodLogProvider>();

    final entry = FoodEntry(
      id: widget.existingEntry?.id,
      timestamp: widget.existingEntry?.timestamp ?? widget.selectedDate,
      mealType: _selectedMealType,
      description: description,
      nutrition: _nutrition,
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

            // Meal type selector
            SegmentedButton<MealType>(
              segments: MealType.values
                  .map((type) => ButtonSegment(
                        value: type,
                        label: Text(type.displayName),
                        icon: Text(type.emoji),
                      ))
                  .toList(),
              selected: {_selectedMealType},
              onSelectionChanged: (selected) {
                setState(() => _selectedMealType = selected.first);
              },
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

  Widget _buildNutritionValue(String label, String value, String unit) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          '$label ($unit)',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
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

  @override
  void initState() {
    super.initState();
    final provider = context.read<FoodLogProvider>();
    final goal = provider.effectiveGoal;
    _caloriesController.text = goal.targetCalories.toString();
    _proteinController.text = (goal.targetProteinGrams ?? 0).toString();
    _carbsController.text = (goal.targetCarbsGrams ?? 0).toString();
    _fatController.text = (goal.targetFatGrams ?? 0).toString();
  }

  @override
  void dispose() {
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  void _save() {
    final goal = NutritionGoal(
      targetCalories: int.tryParse(_caloriesController.text) ?? 2000,
      targetProteinGrams: int.tryParse(_proteinController.text),
      targetCarbsGrams: int.tryParse(_carbsController.text),
      targetFatGrams: int.tryParse(_fatController.text),
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
