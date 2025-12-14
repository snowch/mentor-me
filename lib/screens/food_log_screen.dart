import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';
import '../models/food_entry.dart';
import '../models/food_template.dart';
import '../models/mindful_eating_entry.dart';
import '../providers/food_log_provider.dart';
import '../providers/food_library_provider.dart';
import '../providers/mindful_eating_provider.dart';
import '../providers/weight_provider.dart';
import '../services/ai_service.dart';
import '../services/nutrition_goal_service.dart';
import '../theme/app_spacing.dart';
import '../widgets/food_picker_dialog.dart';
import '../widgets/food_database_search_sheet.dart';
import 'food_library_screen.dart';

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
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _showShareOptions(context),
            tooltip: 'Share Food Log',
          ),
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const FoodLibraryScreen()),
            ),
            tooltip: 'Food Library',
          ),
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
        onPressed: () => _showLogOptionsSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log'),
      ),
    );
  }

  void _showLogOptionsSheet(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.restaurant,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text('Log Food'),
                subtitle: const Text('Track meals with nutrition estimates'),
                onTap: () {
                  Navigator.pop(context);
                  _showAddFoodDialog(context);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  child: Icon(
                    Icons.self_improvement,
                    color: theme.colorScheme.onTertiaryContainer,
                  ),
                ),
                title: const Text('Log Mindful Eating'),
                subtitle: const Text('Track hunger, fullness & mood'),
                onTap: () {
                  Navigator.pop(context);
                  _showMindfulEatingSheet(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMindfulEatingSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => _MindfulEatingSheet(
          scrollController: scrollController,
          selectedDate: _selectedDate,
        ),
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
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Show portion info if available
            if (entry.portionInfo != null)
              Text(
                entry.portionInfo!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            // Show nutrition summary
            if (entry.nutrition != null)
              Text(
                entry.nutrition!.summary,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
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

  void _showShareOptions(BuildContext context) {
    final provider = context.read<FoodLogProvider>();
    final entries = provider.entriesForDate(_selectedDate);

    if (entries.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No food entries to share for this day')),
      );
      return;
    }

    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Share Food Log',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Icon(
                    Icons.copy,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text('Copy to Clipboard'),
                subtitle: const Text('Copy food log as text'),
                onTap: () {
                  Navigator.pop(context);
                  _copyFoodLogToClipboard(context, provider);
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.share,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                title: const Text('Share'),
                subtitle: const Text('Share via other apps'),
                onTap: () {
                  Navigator.pop(context);
                  _shareFoodLog(context, provider);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFoodLogForSharing(FoodLogProvider provider) {
    final summary = provider.summaryForDate(_selectedDate);
    final goal = provider.effectiveGoal;
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final dateStr = isToday ? 'Today' : DateFormat('EEEE, MMMM d, y').format(_selectedDate);

    final buffer = StringBuffer();
    buffer.writeln('📋 Food Log - $dateStr');
    buffer.writeln('═══════════════════════════════');
    buffer.writeln();

    // Daily summary
    buffer.writeln('📊 Daily Summary');
    buffer.writeln('───────────────────────────────');
    buffer.writeln('Calories: ${summary.totalCalories} / ${goal.targetCalories} cal');
    buffer.writeln('Protein: ${summary.totalProtein}g / ${goal.targetProteinGrams ?? 0}g');
    buffer.writeln('Carbs: ${summary.totalCarbs}g / ${goal.targetCarbsGrams ?? 0}g');
    buffer.writeln('Fat: ${summary.totalFat}g / ${goal.targetFatGrams ?? 0}g');
    if (summary.totalFiber > 0) {
      buffer.writeln('Fiber: ${summary.totalFiber}g');
    }
    buffer.writeln();

    // Group entries by meal type
    final entriesByMeal = provider.entriesByMealType(_selectedDate);

    for (final mealType in MealType.values) {
      final mealEntries = entriesByMeal[mealType] ?? [];
      if (mealEntries.isEmpty) continue;

      buffer.writeln('${mealType.emoji} ${mealType.displayName}');
      buffer.writeln('───────────────────────────────');

      for (final entry in mealEntries) {
        buffer.writeln('• ${entry.description}');
        if (entry.nutrition != null) {
          buffer.writeln('  ${entry.nutrition!.calories} cal · ${entry.nutrition!.proteinGrams}g P · ${entry.nutrition!.carbsGrams}g C · ${entry.nutrition!.fatGrams}g F');
        }
        if (entry.notes != null && entry.notes!.isNotEmpty) {
          buffer.writeln('  📝 ${entry.notes}');
        }
      }
      buffer.writeln();
    }

    buffer.writeln('───────────────────────────────');
    buffer.writeln('Logged with MentorMe');

    return buffer.toString();
  }

  void _copyFoodLogToClipboard(BuildContext context, FoodLogProvider provider) {
    final text = _formatFoodLogForSharing(provider);
    Clipboard.setData(ClipboardData(text: text));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Food log copied to clipboard'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareFoodLog(BuildContext context, FoodLogProvider provider) async {
    final text = _formatFoodLogForSharing(provider);
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final dateStr = isToday ? 'Today' : DateFormat('MMM d').format(_selectedDate);

    await Share.share(
      text,
      subject: 'Food Log - $dateStr',
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
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();
  final _imagePicker = ImagePicker();
  MealType _selectedMealType = MealType.lunch;
  NutritionEstimate? _nutrition;
  bool _isEstimating = false;
  String? _estimateError;
  late TimeOfDay _selectedTime;
  String? _imagePath;
  bool _saveToLibrary = false;

  // Unified search state
  String _searchQuery = '';
  List<FoodTemplate> _librarySearchResults = [];
  bool _showSearchDropdown = false;
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;

  // Track nutrition source for proper library attribution
  NutritionSource _nutritionSource = NutritionSource.aiEstimated;

  // Nutrition override controllers
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  bool _nutritionEdited = false; // Track if user has edited values

  // Portion editing state (for entries with portion data)
  double? _portionSize;
  String? _portionUnit;
  double? _gramsConsumed;
  double? _defaultServingSize;
  double? _gramsPerServing;
  final _portionController = TextEditingController();

  // Linked food library template (for accurate portion-based recalculation)
  FoodTemplate? _linkedTemplate;
  bool _hasLoadedTemplate = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _descriptionController.text = widget.existingEntry!.description;
      _selectedMealType = widget.existingEntry!.mealType;
      _nutrition = widget.existingEntry!.nutrition;
      _selectedTime = TimeOfDay.fromDateTime(widget.existingEntry!.timestamp);
      _imagePath = widget.existingEntry!.imagePath;
      // Load portion data if available
      _portionSize = widget.existingEntry!.portionSize;
      _portionUnit = widget.existingEntry!.portionUnit;
      _gramsConsumed = widget.existingEntry!.gramsConsumed;
      _defaultServingSize = widget.existingEntry!.defaultServingSize;
      _gramsPerServing = widget.existingEntry!.gramsPerServing;
      if (_portionSize != null) {
        _portionController.text = _portionSize == _portionSize!.roundToDouble()
            ? _portionSize!.toInt().toString()
            : _portionSize!.toStringAsFixed(2);
      }
      // Populate nutrition controllers if we have existing nutrition
      if (_nutrition != null) {
        _populateNutritionControllers(_nutrition!);
      }
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

    // Setup focus listener for search dropdown
    _searchFocusNode.addListener(_onSearchFocusChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Look up linked template if editing an entry with templateId
    if (!_hasLoadedTemplate && widget.existingEntry?.templateId != null) {
      _hasLoadedTemplate = true;
      final libraryProvider = context.read<FoodLibraryProvider>();
      _linkedTemplate = libraryProvider.getById(widget.existingEntry!.templateId!);
    }
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchFocusNode.removeListener(_onSearchFocusChanged);
    _searchFocusNode.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _portionController.dispose();
    super.dispose();
  }

  void _onSearchFocusChanged() {
    if (_searchFocusNode.hasFocus) {
      _showOverlay();
    } else {
      // Delay hiding to allow tap events on dropdown items
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!_searchFocusNode.hasFocus && mounted) {
          _removeOverlay();
        }
      });
    }
  }

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
    setState(() => _showSearchDropdown = true);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    if (mounted) {
      setState(() => _showSearchDropdown = false);
    }
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width - 40, // Account for padding
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56), // Below the search field
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: _buildSearchDropdownContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchDropdownContent() {
    final theme = Theme.of(context);
    final provider = context.read<FoodLogProvider>();
    final recentFoods = _getRecentFoods(provider);

    return Container(
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Show library results if searching
              if (_searchQuery.isNotEmpty && _librarySearchResults.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      Icon(Icons.folder_outlined, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'From My Library',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ...(_librarySearchResults.take(5).map((template) => _buildLibraryResultTile(template, theme))),
              ],

              // Show "Search online" option
              if (_searchQuery.isNotEmpty) ...[
                if (_librarySearchResults.isNotEmpty)
                  Divider(height: 1, color: theme.colorScheme.outlineVariant),
                InkWell(
                  onTap: () => _searchFoodDatabaseWithQuery(_searchQuery),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.language, size: 20, color: theme.colorScheme.onPrimaryContainer),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Search online for "$_searchQuery"',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Open Food Facts & UK database',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.outline,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.outline),
                      ],
                    ),
                  ),
                ),
              ],

              // Show recent foods when empty
              if (_searchQuery.isEmpty && recentFoods.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      Icon(Icons.history, size: 14, color: theme.colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Recent Foods',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ...recentFoods.take(7).map((food) => _buildRecentFoodTile(food, theme)),
              ],

              // Empty state prompt
              if (_searchQuery.isEmpty && recentFoods.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.search, size: 32, color: theme.colorScheme.outline),
                      const SizedBox(height: 8),
                      Text(
                        'Search your saved foods or online databases',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

              // No library results message
              if (_searchQuery.isNotEmpty && _librarySearchResults.isEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 14, color: theme.colorScheme.outline),
                      const SizedBox(width: 4),
                      Text(
                        'No saved foods match "$_searchQuery"',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLibraryResultTile(FoodTemplate template, ThemeData theme) {
    return InkWell(
      onTap: () {
        _removeOverlay();
        _searchFocusNode.unfocus();
        _quickLogFromLibrary(template);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(template.category.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    template.displayName,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${template.nutritionPerServing.calories} cal · ${template.nutritionPerServing.proteinGrams}g P · ${template.servingText}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline, size: 20, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFoodTile(FoodEntry food, ThemeData theme) {
    return InkWell(
      onTap: () {
        _removeOverlay();
        _searchFocusNode.unfocus();
        _quickLogRecent(food);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Text(food.mealType.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.description,
                    style: theme.textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '${food.nutrition?.calories ?? 0} cal · ${food.nutrition?.proteinGrams ?? 0}g P',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.add_circle_outline, size: 20, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  /// Get recent food entries (last 7 unique foods)
  List<FoodEntry> _getRecentFoods(FoodLogProvider provider) {
    final allEntries = provider.entries;
    final seen = <String>{};
    final recent = <FoodEntry>[];

    // Sort by timestamp descending
    final sorted = List<FoodEntry>.from(allEntries)
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

    for (final entry in sorted) {
      // Use description as key for uniqueness
      final key = entry.description.toLowerCase().trim();
      if (!seen.contains(key) && entry.nutrition != null) {
        seen.add(key);
        recent.add(entry);
        if (recent.length >= 7) break;
      }
    }
    return recent;
  }

  /// Search library by query
  void _searchLibrary(String query) {
    final libraryProvider = context.read<FoodLibraryProvider>();
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _librarySearchResults = [];
      } else {
        _librarySearchResults = libraryProvider.templates
            .where((t) => t.matchesSearch(query))
            .take(5)
            .toList();
      }
    });
    // Update overlay content
    if (_overlayEntry != null) {
      _overlayEntry!.markNeedsBuild();
    }
  }

  /// Open food database search with the current query
  void _searchFoodDatabaseWithQuery(String query) {
    _removeOverlay();
    _searchFocusNode.unfocus();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => FoodDatabaseSearchSheet(
        initialQuery: query,
        onFoodSelected: (result) async {
          // Create a temporary FoodTemplate from the search result
          // Parse serving size (e.g., "100g" -> 100, gram)
          double servingSize = 100.0;
          ServingUnit servingUnit = ServingUnit.gram;
          if (result.servingSize != null) {
            final match = RegExp(r'(\d+(?:\.\d+)?)\s*(g|ml|oz|serving|portion)?', caseSensitive: false)
                .firstMatch(result.servingSize!);
            if (match != null) {
              servingSize = double.tryParse(match.group(1)!) ?? 100.0;
              final unit = match.group(2)?.toLowerCase();
              if (unit == 'ml') {
                servingUnit = ServingUnit.milliliter;
              } else if (unit == 'oz') {
                servingUnit = ServingUnit.ounce;
              } else if (unit == 'serving' || unit == 'portion') {
                servingUnit = ServingUnit.serving;
              }
            }
          }

          final template = FoodTemplate(
            name: result.name,
            brand: result.brand,
            category: FoodCategory.other,
            nutritionPerServing: result.nutrition,
            defaultServingSize: servingSize,
            servingUnit: servingUnit,
            servingDescription: result.servingSize,
            gramsPerServing: servingUnit == ServingUnit.gram ? servingSize : null,
            mlPerServing: servingUnit == ServingUnit.milliliter ? servingSize : null,
            source: NutritionSource.imported,
            barcode: result.barcode,
          );

          // Show portion picker
          if (!mounted) return;
          final entry = await PortionAdjustmentSheet.show(
            context,
            template: template,
            defaultMealType: _selectedMealType,
          );

          if (entry != null && mounted) {
            // Populate form with configured entry data
            setState(() {
              _descriptionController.text = entry.description;
              _nutrition = entry.nutrition;
              _nutritionEdited = false;
              _nutritionSource = NutritionSource.imported;
              _selectedMealType = entry.mealType;
              _selectedTime = TimeOfDay.fromDateTime(entry.timestamp);
              if (entry.nutrition != null) {
                _populateNutritionControllers(entry.nutrition!);
              }
            });
          }
        },
      ),
    ).then((_) {
      // Refresh library search when sheet closes to pick up any newly saved items
      if (mounted && _searchQuery.isNotEmpty) {
        _searchLibrary(_searchQuery);
      }
    });
  }

  /// Quick log a recent food entry
  Future<void> _quickLogRecent(FoodEntry entry) async {
    final provider = context.read<FoodLogProvider>();

    // Create new entry with current date/time
    final now = DateTime.now();
    final timestamp = DateTime(
      widget.selectedDate.year,
      widget.selectedDate.month,
      widget.selectedDate.day,
      now.hour,
      now.minute,
    );

    final newEntry = FoodEntry(
      timestamp: timestamp,
      mealType: _selectedMealType,
      description: entry.description,
      nutrition: entry.nutrition,
      imagePath: entry.imagePath,
    );

    provider.addEntry(newEntry);
    widget.onSaved?.call();
    Navigator.pop(context);
  }

  /// Quick log from library template - shows portion picker then populates form
  Future<void> _quickLogFromLibrary(FoodTemplate template) async {
    // Show portion picker WITHOUT closing the form first
    final entry = await PortionAdjustmentSheet.show(
      context,
      template: template,
      defaultMealType: _selectedMealType,
    );

    if (entry != null && mounted) {
      // Populate the form with the configured entry data
      setState(() {
        _descriptionController.text = entry.description;
        _nutrition = entry.nutrition;
        _nutritionEdited = false;
        _nutritionSource = template.source;
        _selectedMealType = entry.mealType;
        _selectedTime = TimeOfDay.fromDateTime(entry.timestamp);
        if (entry.nutrition != null) {
          _populateNutritionControllers(entry.nutrition!);
        }
      });

      // Update library usage
      context.read<FoodLibraryProvider>().recordUsage(template.id);
    }
  }

  /// Populate the nutrition text field controllers from a NutritionEstimate
  void _populateNutritionControllers(NutritionEstimate nutrition) {
    _caloriesController.text = nutrition.calories.toString();
    _proteinController.text = nutrition.proteinGrams.toString();
    _carbsController.text = nutrition.carbsGrams.toString();
    _fatController.text = nutrition.fatGrams.toString();
  }

  /// Get the current nutrition values from text fields (with user overrides)
  NutritionEstimate? _getCurrentNutrition() {
    if (_nutrition == null) return null;

    return NutritionEstimate(
      calories: int.tryParse(_caloriesController.text) ?? _nutrition!.calories,
      proteinGrams: int.tryParse(_proteinController.text) ?? _nutrition!.proteinGrams,
      carbsGrams: int.tryParse(_carbsController.text) ?? _nutrition!.carbsGrams,
      fatGrams: int.tryParse(_fatController.text) ?? _nutrition!.fatGrams,
      // Preserve other fields from original estimate
      fiberGrams: _nutrition!.fiberGrams,
      sugarGrams: _nutrition!.sugarGrams,
      sodiumMg: _nutrition!.sodiumMg,
      saturatedFatGrams: _nutrition!.saturatedFatGrams,
      unsaturatedFatGrams: _nutrition!.unsaturatedFatGrams,
      cholesterolMg: _nutrition!.cholesterolMg,
      potassiumMg: _nutrition!.potassiumMg,
      confidence: _nutritionEdited ? 'User edited' : _nutrition!.confidence,
    );
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
          _nutritionEdited = false; // Reset edited flag on new estimate
          if (estimate != null) {
            _populateNutritionControllers(estimate);
          } else {
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
            _nutritionEdited = false; // Reset edited flag on new analysis
            if (analysis.nutrition != null) {
              _populateNutritionControllers(analysis.nutrition!);
            }
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

  Future<void> _confirmDeleteEntry(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: Text('Are you sure you want to delete "${widget.existingEntry?.description}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<FoodLogProvider>();
      provider.deleteEntry(widget.existingEntry!.id);
      widget.onSaved?.call();
      Navigator.pop(context);
    }
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

    // Use _getCurrentNutrition() to capture any user edits
    final finalNutrition = _getCurrentNutrition();

    // Calculate grams consumed if portion data is available
    double? calculatedGrams = _gramsConsumed;
    if (_portionSize != null && _gramsPerServing != null) {
      calculatedGrams = _gramsPerServing! * _portionSize!;
    }

    final entry = FoodEntry(
      id: widget.existingEntry?.id,
      timestamp: timestamp,
      mealType: _selectedMealType,
      description: description,
      nutrition: finalNutrition,
      imagePath: _imagePath,
      templateId: widget.existingEntry?.templateId, // Preserve link to food library
      portionSize: _portionSize,
      portionUnit: _portionUnit,
      gramsConsumed: calculatedGrams,
      defaultServingSize: _defaultServingSize,
      gramsPerServing: _gramsPerServing,
    );

    try {
      if (widget.existingEntry != null) {
        provider.updateEntry(entry);
      } else {
        provider.addEntry(entry);

        // Save to library if checkbox is checked and nutrition is available
        if (_saveToLibrary && finalNutrition != null) {
          final libraryProvider = context.read<FoodLibraryProvider>();
          final template = FoodTemplate(
            name: description,
            category: FoodCategory.other, // Default category
            nutritionPerServing: finalNutrition,
            defaultServingSize: 1,
            servingUnit: ServingUnit.serving,
            source: _nutritionEdited ? NutritionSource.manual : _nutritionSource,
            sourceNotes: 'Added from Food Log',
          );
          libraryProvider.addTemplate(template);
        }
      }

      widget.onSaved?.call();
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
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
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.existingEntry != null)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Delete entry',
                        onPressed: () => _confirmDeleteEntry(context),
                      ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,

            // Quick add section with unified search (only for new entries)
            if (widget.existingEntry == null) ...[
              // Unified search field with dropdown
              CompositedTransformTarget(
                link: _layerLink,
                child: TextField(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search foods...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchLibrary('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: _searchLibrary,
                  onTap: () {
                    if (!_showSearchDropdown) {
                      _showOverlay();
                    }
                  },
                ),
              ),

              AppSpacing.gapVerticalSm,
              Row(
                children: [
                  const Expanded(child: Divider()),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'or add manually',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider()),
                ],
              ),
              AppSpacing.gapVerticalMd,
            ],

            // Meal type and time row
            Row(
              children: [
                // Meal type selector
                Expanded(
                  child: SegmentedButton<MealType>(
                    segments: MealType.values
                        .map((type) => ButtonSegment(
                              value: type,
                              label: Text(type.emoji, style: const TextStyle(fontSize: 18)),
                              tooltip: type.displayName,
                            ))
                        .toList(),
                    selected: {_selectedMealType},
                    onSelectionChanged: (selected) {
                      setState(() => _selectedMealType = selected.first);
                    },
                    showSelectedIcon: false,
                  ),
                ),
                const SizedBox(width: 8),
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
                  icon: const Icon(Icons.access_time, size: 18),
                  label: Text(_selectedTime.format(context)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  ),
                ),
              ],
            ),
            AppSpacing.gapVerticalMd,

            // Photo capture section
            _buildPhotoSection(theme),
            AppSpacing.gapVerticalMd,

            // Notes field (renamed from "What did you eat?")
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Food Description',
                hintText: 'e.g., Grilled chicken salad with ranch dressing',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}), // Rebuild to show/hide AI button
            ),

            // Portion editing section (only show for entries with portion data)
            if (_portionSize != null && _portionUnit != null) ...[
              AppSpacing.gapVerticalMd,
              _buildPortionEditingSection(theme),
            ],

            // AI Estimate button - only show as fallback when no nutrition
            if (_nutrition == null && _descriptionController.text.isNotEmpty) ...[
              AppSpacing.gapVerticalMd,
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
            ],

            if (_estimateError != null) ...[
              AppSpacing.gapVerticalSm,
              Text(
                _estimateError!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ],

            // Nutrition display with editable fields
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
                            _nutritionEdited ? 'Nutrition (edited)' : 'Estimated Nutrition',
                            style: theme.textTheme.titleSmall,
                          ),
                          if (_nutrition!.confidence != null && !_nutritionEdited)
                            Chip(
                              label: Text(
                                _nutrition!.confidence!,
                                style: theme.textTheme.bodySmall,
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                          if (_nutritionEdited)
                            Chip(
                              label: const Text('User edited'),
                              backgroundColor: theme.colorScheme.primaryContainer,
                              visualDensity: VisualDensity.compact,
                            ),
                        ],
                      ),
                      AppSpacing.gapVerticalSm,
                      // Editable nutrition fields
                      Row(
                        children: [
                          Expanded(
                            child: _buildEditableNutritionField(
                              controller: _caloriesController,
                              label: 'Calories',
                              suffix: 'cal',
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildEditableNutritionField(
                              controller: _proteinController,
                              label: 'Protein',
                              suffix: 'g',
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildEditableNutritionField(
                              controller: _carbsController,
                              label: 'Carbs',
                              suffix: 'g',
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildEditableNutritionField(
                              controller: _fatController,
                              label: 'Fat',
                              suffix: 'g',
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      // Fat breakdown row (always shown for consistency)
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
                      // Show mono/poly if available, otherwise show combined unsaturated
                      if (_nutrition!.monoFatGrams != null || _nutrition!.polyFatGrams != null) ...[
                        // Detailed breakdown with mono/poly
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
                              'Mono',
                              '${_nutrition!.monoFatGrams ?? 0}',
                              'g',
                              color: Colors.green.shade700,
                            ),
                            _buildNutritionValue(
                              'Poly',
                              '${_nutrition!.polyFatGrams ?? 0}',
                              'g',
                              color: Colors.green.shade500,
                            ),
                            _buildNutritionValue(
                              'Trans',
                              '${_nutrition!.transFatGrams ?? 0}',
                              'g',
                              color: theme.colorScheme.error,
                            ),
                          ],
                        ),
                      ] else ...[
                        // Simple breakdown with combined unsaturated
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

            // Save to Library checkbox (only for new entries with nutrition)
            if (widget.existingEntry == null && _nutrition != null)
              CheckboxListTile(
                value: _saveToLibrary,
                onChanged: (value) => setState(() => _saveToLibrary = value ?? false),
                title: const Text('Save to Food Library'),
                subtitle: const Text('Quick access next time'),
                secondary: const Icon(Icons.bookmark_add_outlined),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),

            if (widget.existingEntry == null && _nutrition != null)
              AppSpacing.gapVerticalSm,

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

  /// Build the portion editing section for entries with portion data
  Widget _buildPortionEditingSection(ThemeData theme) {
    // Calculate current consumed amount display
    String consumedDisplay = '';
    if (_gramsConsumed != null && _portionUnit != 'g') {
      final gramsStr = _gramsConsumed == _gramsConsumed!.roundToDouble()
          ? _gramsConsumed!.toInt().toString()
          : _gramsConsumed!.toStringAsFixed(1);
      consumedDisplay = '= ${gramsStr}g';
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.straighten, size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Portion Size',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                // Show linked library indicator
                if (_linkedTemplate != null)
                  Tooltip(
                    message: 'Linked to "${_linkedTemplate!.name}" in Food Library\nNutrition recalculates from library data',
                    child: Chip(
                      avatar: Icon(Icons.link, size: 16, color: theme.colorScheme.primary),
                      label: Text(
                        'From Library',
                        style: theme.textTheme.labelSmall,
                      ),
                      visualDensity: VisualDensity.compact,
                      backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.5),
                    ),
                  )
                else if (widget.existingEntry?.templateId != null)
                  // Template ID exists but template not found (may have been deleted)
                  Tooltip(
                    message: 'Original library item not found\nUsing stored nutrition data',
                    child: Chip(
                      avatar: Icon(Icons.link_off, size: 16, color: theme.colorScheme.outline),
                      label: Text(
                        'Unlinked',
                        style: theme.textTheme.labelSmall,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
              ],
            ),
            AppSpacing.gapVerticalMd,
            Row(
              children: [
                // Portion stepper
                IconButton.filled(
                  onPressed: (_portionSize ?? 1) > 0.25
                      ? () {
                          setState(() {
                            _portionSize = (_portionSize ?? 1) - 0.25;
                            _portionController.text = _formatPortionSize(_portionSize!);
                            _updateGramsConsumed();
                            _recalculateNutritionFromPortion();
                          });
                        }
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _portionController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: InputDecoration(
                      suffixText: _portionUnit ?? 'servings',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    onChanged: (value) {
                      final parsed = double.tryParse(value);
                      if (parsed != null && parsed > 0) {
                        setState(() {
                          _portionSize = parsed;
                          _updateGramsConsumed();
                          _recalculateNutritionFromPortion();
                        });
                      }
                    },
                  ),
                ),
                const SizedBox(width: 12),
                IconButton.filled(
                  onPressed: () {
                    setState(() {
                      _portionSize = (_portionSize ?? 1) + 0.25;
                      _portionController.text = _formatPortionSize(_portionSize!);
                      _updateGramsConsumed();
                      _recalculateNutritionFromPortion();
                    });
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            if (consumedDisplay.isNotEmpty) ...[
              AppSpacing.gapVerticalSm,
              Center(
                child: Text(
                  consumedDisplay,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
            // Quick portion buttons
            AppSpacing.gapVerticalSm,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [0.5, 1.0, 1.5, 2.0].map((value) {
                final isSelected = _portionSize == value;
                return ChoiceChip(
                  label: Text(value == value.roundToDouble()
                      ? value.toInt().toString()
                      : value.toString()),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _portionSize = value;
                        _portionController.text = _formatPortionSize(value);
                        _updateGramsConsumed();
                        _recalculateNutritionFromPortion();
                      });
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPortionSize(double size) {
    return size == size.roundToDouble()
        ? size.toInt().toString()
        : size.toStringAsFixed(2);
  }

  void _updateGramsConsumed() {
    if (_portionSize != null && _gramsPerServing != null) {
      _gramsConsumed = _gramsPerServing! * _portionSize!;
    }
  }

  void _recalculateNutritionFromPortion() {
    if (_nutrition == null || _portionSize == null) return;

    NutritionEstimate scaledNutrition;

    // If we have a linked template, use its per-serving nutrition for accurate recalculation
    if (_linkedTemplate != null) {
      // Calculate nutrition directly from template's per-serving data
      // The template's nutritionForAmount method handles scaling properly
      scaledNutrition = _linkedTemplate!.nutritionForAmount(
        _linkedTemplate!.defaultServingSize * _portionSize!,
      );
    } else if (widget.existingEntry != null) {
      // Fallback: scale from original entry's nutrition
      final originalPortion = widget.existingEntry!.portionSize;
      if (originalPortion == null || originalPortion == 0) return;

      // Calculate multiplier from original portion to new portion
      final multiplier = _portionSize! / originalPortion;

      // Get original nutrition values
      final origNutrition = widget.existingEntry!.nutrition;
      if (origNutrition == null) return;

      // Scale nutrition by multiplier
      scaledNutrition = NutritionEstimate(
        calories: (origNutrition.calories * multiplier).round(),
        proteinGrams: (origNutrition.proteinGrams * multiplier).round(),
        carbsGrams: (origNutrition.carbsGrams * multiplier).round(),
        fatGrams: (origNutrition.fatGrams * multiplier).round(),
        saturatedFatGrams: origNutrition.saturatedFatGrams != null
            ? (origNutrition.saturatedFatGrams! * multiplier).round()
            : null,
        unsaturatedFatGrams: origNutrition.unsaturatedFatGrams != null
            ? (origNutrition.unsaturatedFatGrams! * multiplier).round()
            : null,
        monoFatGrams: origNutrition.monoFatGrams != null
            ? (origNutrition.monoFatGrams! * multiplier).round()
            : null,
        polyFatGrams: origNutrition.polyFatGrams != null
            ? (origNutrition.polyFatGrams! * multiplier).round()
            : null,
        transFatGrams: origNutrition.transFatGrams != null
            ? (origNutrition.transFatGrams! * multiplier).round()
            : null,
        fiberGrams: origNutrition.fiberGrams != null
            ? (origNutrition.fiberGrams! * multiplier).round()
            : null,
        sugarGrams: origNutrition.sugarGrams != null
            ? (origNutrition.sugarGrams! * multiplier).round()
            : null,
        sodiumMg: origNutrition.sodiumMg != null
            ? (origNutrition.sodiumMg! * multiplier).round()
            : null,
        potassiumMg: origNutrition.potassiumMg != null
            ? (origNutrition.potassiumMg! * multiplier).round()
            : null,
        cholesterolMg: origNutrition.cholesterolMg != null
            ? (origNutrition.cholesterolMg! * multiplier).round()
            : null,
        confidence: origNutrition.confidence,
        notes: origNutrition.notes,
      );
    } else {
      return;
    }

    setState(() {
      _nutrition = scaledNutrition;
      _populateNutritionControllers(scaledNutrition);
    });
  }

  /// Build an editable nutrition text field
  Widget _buildEditableNutritionField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    Color? color,
    int maxLength = 5, // Default max 5 digits (99,999)
  }) {
    final theme = Theme.of(context);

    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      maxLength: maxLength,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
      ],
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: color,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: theme.textTheme.bodySmall?.copyWith(
          color: color ?? theme.colorScheme.outline,
        ),
        suffixText: suffix,
        suffixStyle: theme.textTheme.bodySmall?.copyWith(
          color: color ?? theme.colorScheme.outline,
        ),
        counterText: '', // Hide the character counter
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color ?? theme.colorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: (color ?? theme.colorScheme.outline).withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: color ?? theme.colorScheme.primary, width: 2),
        ),
      ),
      onChanged: (value) {
        // Mark as edited when user changes values
        if (!_nutritionEdited) {
          setState(() => _nutritionEdited = true);
        }
      },
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
        padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 100),
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

/// Bottom sheet for logging standalone mindful eating entries
class _MindfulEatingSheet extends StatefulWidget {
  final ScrollController scrollController;
  final DateTime selectedDate;
  /// Used for editing existing entries
  final MindfulEatingEntry? existingEntry;

  const _MindfulEatingSheet({
    required this.scrollController,
    required this.selectedDate,
    // ignore: unused_element
    this.existingEntry,
  });

  @override
  State<_MindfulEatingSheet> createState() => _MindfulEatingSheetState();
}

class _MindfulEatingSheetState extends State<_MindfulEatingSheet> {
  // Mindful eating state
  MindfulEatingTiming _timing = MindfulEatingTiming.beforeEating;
  int? _level;
  Set<String> _selectedMoods = {};
  final _noteController = TextEditingController();

  // Custom mood input state
  bool _showCustomMoodInput = false;
  final _customMoodController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingEntry != null) {
      _timing = widget.existingEntry!.timing;
      _level = widget.existingEntry!.level;
      _selectedMoods = Set.from(widget.existingEntry!.mood ?? []);
      _noteController.text = widget.existingEntry!.note ?? '';
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    _customMoodController.dispose();
    super.dispose();
  }

  /// Get level labels based on timing
  List<String> get _levelLabels {
    switch (_timing) {
      case MindfulEatingTiming.beforeEating:
        return MealMoodPresets.hungerLabels;
      case MindfulEatingTiming.afterEating:
        return MealMoodPresets.fullnessLabels;
      case MindfulEatingTiming.other:
        return ['Very Low', 'Low', 'Moderate', 'High', 'Very High'];
    }
  }

  /// Get level question based on timing
  String get _levelQuestion {
    switch (_timing) {
      case MindfulEatingTiming.beforeEating:
        return 'How hungry are you?';
      case MindfulEatingTiming.afterEating:
        return 'How full are you?';
      case MindfulEatingTiming.other:
        return 'Rate your level (1-5)';
    }
  }

  /// Get mood presets based on timing
  List<MoodOption> get _moodPresets {
    switch (_timing) {
      case MindfulEatingTiming.beforeEating:
        return MealMoodPresets.beforeMeal;
      case MindfulEatingTiming.afterEating:
        return MealMoodPresets.afterMeal;
      case MindfulEatingTiming.other:
        // Combined moods for "other" timing
        return [
          ...MealMoodPresets.beforeMeal,
          ...MealMoodPresets.afterMeal,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foodLogProvider = context.read<FoodLogProvider>();
    final customMoods = _timing == MindfulEatingTiming.beforeEating
        ? foodLogProvider.customMoodsBefore
        : foodLogProvider.customMoodsAfter;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.self_improvement, color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  widget.existingEntry != null
                      ? 'Edit Mindful Eating'
                      : 'Log Mindful Eating',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),

          const Divider(),

          // Content
          Expanded(
            child: ListView(
              controller: widget.scrollController,
              padding: const EdgeInsets.all(16),
              children: [
                // Timing selector
                Text(
                  'When is this check-in?',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SegmentedButton<MindfulEatingTiming>(
                  segments: MindfulEatingTiming.values.map((timing) {
                    return ButtonSegment<MindfulEatingTiming>(
                      value: timing,
                      label: Text(timing.displayName),
                      icon: Text(timing.emoji),
                    );
                  }).toList(),
                  selected: {_timing},
                  onSelectionChanged: (selected) {
                    setState(() {
                      _timing = selected.first;
                      // Reset level and moods when timing changes
                      _level = null;
                      _selectedMoods.clear();
                    });
                  },
                ),

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Level selector
                _buildLevelSelector(
                  theme: theme,
                  label: _levelQuestion,
                  value: _level,
                  labels: _levelLabels,
                  onChanged: (value) => setState(() => _level = value),
                ),

                const SizedBox(height: 24),

                // Mood selector
                Text(
                  'How are you feeling?',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                _buildMoodSelector(
                  theme: theme,
                  presets: _moodPresets,
                  customMoods: customMoods,
                  selectedMoods: _selectedMoods,
                  onToggle: (id) => setState(() {
                    if (_selectedMoods.contains(id)) {
                      _selectedMoods.remove(id);
                    } else {
                      _selectedMoods.add(id);
                    }
                  }),
                  showCustomInput: _showCustomMoodInput,
                  onToggleCustomInput: () => setState(() {
                    _showCustomMoodInput = !_showCustomMoodInput;
                  }),
                  customController: _customMoodController,
                  onSaveCustom: () async {
                    final mood = _customMoodController.text.trim();
                    if (mood.isNotEmpty) {
                      if (_timing == MindfulEatingTiming.beforeEating) {
                        await foodLogProvider.addCustomMoodBefore(mood);
                      } else {
                        await foodLogProvider.addCustomMoodAfter(mood);
                      }
                      _selectedMoods.add(mood);
                      _customMoodController.clear();
                      setState(() => _showCustomMoodInput = false);
                    }
                  },
                  onRemoveCustom: (mood) async {
                    if (_timing == MindfulEatingTiming.beforeEating) {
                      await foodLogProvider.removeCustomMoodBefore(mood);
                    } else {
                      await foodLogProvider.removeCustomMoodAfter(mood);
                    }
                    _selectedMoods.remove(mood);
                    setState(() {});
                  },
                ),

                const SizedBox(height: 24),

                // Note field
                Text(
                  'Notes (optional)',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    hintText: 'Any reflections on this eating experience...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                ),

                const SizedBox(height: 24),

                // Save button
                FilledButton.icon(
                  onPressed: _hasData ? _save : null,
                  icon: const Icon(Icons.check),
                  label: Text(widget.existingEntry != null ? 'Update' : 'Save'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _hasData =>
      _level != null ||
      _selectedMoods.isNotEmpty ||
      _noteController.text.trim().isNotEmpty;

  Future<void> _save() async {
    final provider = context.read<MindfulEatingProvider>();

    final entry = MindfulEatingEntry(
      id: widget.existingEntry?.id,
      timestamp: widget.existingEntry?.timestamp ??
          DateTime(
            widget.selectedDate.year,
            widget.selectedDate.month,
            widget.selectedDate.day,
            DateTime.now().hour,
            DateTime.now().minute,
          ),
      timing: _timing,
      level: _level,
      mood: _selectedMoods.isNotEmpty ? _selectedMoods.toList() : null,
      note: _noteController.text.trim().isNotEmpty ? _noteController.text.trim() : null,
    );

    if (widget.existingEntry != null) {
      await provider.updateEntry(entry);
    } else {
      await provider.addEntry(entry);
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingEntry != null
              ? 'Mindful eating entry updated'
              : 'Mindful eating logged'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Build a 1-5 level selector
  Widget _buildLevelSelector({
    required ThemeData theme,
    required String label,
    required int? value,
    required List<String> labels,
    required ValueChanged<int?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: theme.textTheme.bodyMedium),
            if (value != null) ...[
              const Spacer(),
              Text(
                labels[value - 1],
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final level = index + 1;
            final isSelected = value == level;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 4 ? 8 : 0),
                child: InkWell(
                  onTap: () => onChanged(isSelected ? null : level),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primaryContainer
                          : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: isSelected
                          ? Border.all(color: theme.colorScheme.primary, width: 2)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$level',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: isSelected ? FontWeight.bold : null,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  /// Build a mood chip selector
  Widget _buildMoodSelector({
    required ThemeData theme,
    required List<MoodOption> presets,
    required List<String> customMoods,
    required Set<String> selectedMoods,
    required Function(String) onToggle,
    required bool showCustomInput,
    required VoidCallback onToggleCustomInput,
    required TextEditingController customController,
    required VoidCallback onSaveCustom,
    required Function(String) onRemoveCustom,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Preset moods
            ...presets.map((mood) {
              final isSelected = selectedMoods.contains(mood.id);
              return FilterChip(
                label: Text('${mood.emoji} ${mood.label}'),
                selected: isSelected,
                onSelected: (_) => onToggle(mood.id),
              );
            }),
            // Custom moods
            ...customMoods.map((mood) {
              final isSelected = selectedMoods.contains(mood);
              return FilterChip(
                label: Text('✨ $mood'),
                selected: isSelected,
                onSelected: (_) => onToggle(mood),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () => onRemoveCustom(mood),
              );
            }),
            // "Other" button
            ActionChip(
              label: const Text('+ Other'),
              onPressed: onToggleCustomInput,
            ),
          ],
        ),
        // Custom mood input
        if (showCustomInput) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: customController,
                  decoration: InputDecoration(
                    hintText: 'Enter custom feeling',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  onSubmitted: (_) => onSaveCustom(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: onSaveCustom,
                icon: const Icon(Icons.check),
              ),
              IconButton(
                onPressed: onToggleCustomInput,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
