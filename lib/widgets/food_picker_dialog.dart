import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_template.dart';
import '../models/food_entry.dart';
import '../providers/food_library_provider.dart';

/// Dialog for selecting a food from the library
class FoodPickerDialog extends StatefulWidget {
  final MealType? defaultMealType;

  const FoodPickerDialog({
    super.key,
    this.defaultMealType,
  });

  /// Show the dialog and return the selected food entry
  static Future<FoodEntry?> show(
    BuildContext context, {
    MealType? defaultMealType,
  }) async {
    return showModalBottomSheet<FoodEntry>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FoodPickerDialog(defaultMealType: defaultMealType),
    );
  }

  @override
  State<FoodPickerDialog> createState() => _FoodPickerDialogState();
}

class _FoodPickerDialogState extends State<FoodPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filter = 'all'; // 'all', 'recent', 'frequent', 'favorites'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodTemplate> _getFilteredTemplates(FoodLibraryProvider provider) {
    List<FoodTemplate> templates;

    switch (_filter) {
      case 'recent':
        templates = provider.recentlyUsed;
        break;
      case 'frequent':
        templates = provider.frequentlyUsed;
        break;
      case 'favorites':
        templates = provider.favorites;
        break;
      default:
        templates = provider.templates;
    }

    if (_searchQuery.isNotEmpty) {
      templates = templates.where((t) => t.matchesSearch(_searchQuery)).toList();
    }

    // Sort by name for 'all' filter
    if (_filter == 'all') {
      templates.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return templates;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'Add from Library',
                  style: theme.textTheme.headlineSmall,
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search foods...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),

          // Filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All',
                  icon: Icons.list,
                  selected: _filter == 'all',
                  onSelected: () => setState(() => _filter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Recent',
                  icon: Icons.history,
                  selected: _filter == 'recent',
                  onSelected: () => setState(() => _filter = 'recent'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Frequent',
                  icon: Icons.trending_up,
                  selected: _filter == 'frequent',
                  onSelected: () => setState(() => _filter = 'frequent'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Favorites',
                  icon: Icons.favorite,
                  selected: _filter == 'favorites',
                  onSelected: () => setState(() => _filter = 'favorites'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Food list
          Expanded(
            child: Consumer<FoodLibraryProvider>(
              builder: (context, provider, child) {
                final templates = _getFilteredTemplates(provider);

                if (templates.isEmpty) {
                  return _buildEmptyState(context, provider);
                }

                return ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: templates.length,
                  itemBuilder: (context, index) {
                    final template = templates[index];
                    return _FoodPickerItem(
                      template: template,
                      onTap: () => _selectFood(context, template, provider),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, FoodLibraryProvider provider) {
    final theme = Theme.of(context);

    if (_searchQuery.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No foods match "$_searchQuery"',
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    if (_filter == 'favorites' && provider.favorites.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text('No favorites yet'),
            const SizedBox(height: 8),
            Text(
              'Tap the heart on foods you eat often',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (provider.templates.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            const Text('Your food library is empty'),
            const SizedBox(height: 8),
            Text(
              'Add foods to build your library',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return const Center(child: Text('No foods found'));
  }

  Future<void> _selectFood(
    BuildContext context,
    FoodTemplate template,
    FoodLibraryProvider provider,
  ) async {
    final entry = await PortionAdjustmentSheet.show(
      context,
      template: template,
      defaultMealType: widget.defaultMealType,
    );

    if (entry != null) {
      // Record usage
      await provider.recordUsage(template.id);

      if (context.mounted) {
        Navigator.pop(context, entry);
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  const _FilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _FoodPickerItem extends StatelessWidget {
  final FoodTemplate template;
  final VoidCallback onTap;

  const _FoodPickerItem({
    required this.template,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(
          template.category.emoji,
          style: const TextStyle(fontSize: 20),
        ),
      ),
      title: Text(
        template.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${template.nutritionPerServing.calories} cal · ${template.servingText}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (template.isFavorite)
            Icon(
              Icons.favorite,
              size: 16,
              color: colorScheme.error,
            ),
          const SizedBox(width: 4),
          Icon(
            Icons.chevron_right,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for adjusting portion size before adding to log
class PortionAdjustmentSheet extends StatefulWidget {
  final FoodTemplate template;
  final MealType? defaultMealType;

  const PortionAdjustmentSheet({
    super.key,
    required this.template,
    this.defaultMealType,
  });

  /// Show the sheet and return the configured food entry
  static Future<FoodEntry?> show(
    BuildContext context, {
    required FoodTemplate template,
    MealType? defaultMealType,
  }) async {
    return showModalBottomSheet<FoodEntry>(
      context: context,
      isScrollControlled: true,
      builder: (context) => PortionAdjustmentSheet(
        template: template,
        defaultMealType: defaultMealType,
      ),
    );
  }

  @override
  State<PortionAdjustmentSheet> createState() => _PortionAdjustmentSheetState();
}

class _PortionAdjustmentSheetState extends State<PortionAdjustmentSheet> {
  late double _servings;
  late MealType _mealType;
  late TimeOfDay _time;
  final TextEditingController _customServingsController = TextEditingController();
  bool _showCustomInput = false;

  @override
  void initState() {
    super.initState();
    _servings = 1.0;
    _mealType = widget.defaultMealType ?? _suggestMealType();
    _time = TimeOfDay.now();
    _customServingsController.text = _servings.toString();
  }

  @override
  void dispose() {
    _customServingsController.dispose();
    super.dispose();
  }

  MealType _suggestMealType() {
    final hour = DateTime.now().hour;
    if (hour < 10) return MealType.breakfast;
    if (hour < 14) return MealType.lunch;
    if (hour < 17) return MealType.snack;
    return MealType.dinner;
  }

  NutritionEstimate get _scaledNutrition {
    return widget.template.nutritionForAmount(
      widget.template.defaultServingSize * _servings,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nutrition = _scaledNutrition;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Food info
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.template.category.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.template.name,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (widget.template.brand != null)
                        Text(
                          widget.template.brand!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      Text(
                        '${widget.template.nutritionPerServing.calories} cal per ${widget.template.servingText}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Serving adjustment
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'How many servings?',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  // Serving selector - toggle between stepper and custom input
                  if (_showCustomInput)
                    // Custom input mode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 120,
                          child: TextField(
                            controller: _customServingsController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineMedium,
                            decoration: InputDecoration(
                              hintText: '1.0',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: (value) {
                              final parsed = double.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                setState(() => _servings = parsed);
                              }
                            },
                            onSubmitted: (value) {
                              final parsed = double.tryParse(value);
                              if (parsed != null && parsed > 0) {
                                setState(() {
                                  _servings = parsed;
                                  _showCustomInput = false;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          onPressed: () {
                            final parsed = double.tryParse(_customServingsController.text);
                            if (parsed != null && parsed > 0) {
                              setState(() {
                                _servings = parsed;
                                _showCustomInput = false;
                              });
                            }
                          },
                          icon: const Icon(Icons.check),
                          style: IconButton.styleFrom(
                            backgroundColor: colorScheme.primaryContainer,
                          ),
                        ),
                      ],
                    )
                  else
                    // Stepper mode
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton.filled(
                          onPressed: _servings > 0.25
                              ? () => setState(() {
                                    _servings -= 0.25;
                                    _customServingsController.text = _servings.toString();
                                  })
                              : null,
                          icon: const Icon(Icons.remove),
                        ),
                        const SizedBox(width: 24),
                        GestureDetector(
                          onTap: () => setState(() {
                            _showCustomInput = true;
                            _customServingsController.text = _servings.toString();
                          }),
                          child: Container(
                            width: 80,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: colorScheme.outline.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _servings == _servings.roundToDouble()
                                  ? _servings.toInt().toString()
                                  : _servings.toStringAsFixed(2),
                              style: theme.textTheme.headlineMedium,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        IconButton.filled(
                          onPressed: () => setState(() {
                            _servings += 0.25;
                            _customServingsController.text = _servings.toString();
                          }),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  Text(
                    _servings == 1
                        ? widget.template.servingText
                        : '${(_servings * widget.template.defaultServingSize).toStringAsFixed(1)} ${widget.template.servingUnit.pluralName}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),

                  // Quick buttons + custom option
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      // Quick select buttons
                      ...[0.5, 1.0, 1.5, 2.0].map((value) {
                        final isSelected = _servings == value && !_showCustomInput;
                        return ChoiceChip(
                          label: Text(value == value.roundToDouble()
                              ? value.toInt().toString()
                              : value.toString()),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _servings = value;
                                _showCustomInput = false;
                                _customServingsController.text = value.toString();
                              });
                            }
                          },
                        );
                      }),
                      // Custom button
                      ActionChip(
                        label: const Text('Custom'),
                        avatar: Icon(
                          Icons.edit,
                          size: 18,
                          color: _showCustomInput
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        backgroundColor: _showCustomInput
                            ? colorScheme.primaryContainer
                            : null,
                        onPressed: () => setState(() {
                          _showCustomInput = true;
                          _customServingsController.text = _servings.toString();
                        }),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Meal type and time
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<MealType>(
                    value: _mealType,
                    decoration: const InputDecoration(
                      labelText: 'Meal',
                      border: OutlineInputBorder(),
                    ),
                    items: MealType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text('${type.emoji} ${type.displayName}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _mealType = value);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (time != null) {
                        setState(() => _time = time);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Time',
                        border: OutlineInputBorder(),
                      ),
                      child: Text(_time.format(context)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Nutrition summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'Nutrition for ${_servings == 1 ? '1 serving' : '$_servings servings'}',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _NutrientDisplay(
                        value: nutrition.calories,
                        label: 'Calories',
                        unit: '',
                      ),
                      _NutrientDisplay(
                        value: nutrition.proteinGrams,
                        label: 'Protein',
                        unit: 'g',
                      ),
                      _NutrientDisplay(
                        value: nutrition.carbsGrams,
                        label: 'Carbs',
                        unit: 'g',
                      ),
                      _NutrientDisplay(
                        value: nutrition.fatGrams,
                        label: 'Fat',
                        unit: 'g',
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Add button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _addToLog,
                icon: const Icon(Icons.add),
                label: const Text('Add to Food Log'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addToLog() {
    final now = DateTime.now();
    final timestamp = DateTime(
      now.year,
      now.month,
      now.day,
      _time.hour,
      _time.minute,
    );

    final entry = widget.template.toFoodEntry(
      mealType: _mealType,
      timestamp: timestamp,
      servingMultiplier: _servings,
    );

    Navigator.pop(context, entry);
  }
}

class _NutrientDisplay extends StatelessWidget {
  final double value;
  final String label;
  final String unit;

  const _NutrientDisplay({
    required this.value,
    required this.label,
    required this.unit,
  });

  String _formatValue() {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          '${_formatValue()}$unit',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
