// lib/widgets/food_log_widget.dart
// Food log tracking widget for home/mentor screen
// Shows today's food summary with quick add button

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/food_log_provider.dart';
import '../providers/settings_provider.dart';
import '../screens/food_log_screen.dart';
import '../theme/app_spacing.dart';
import '../models/food_entry.dart';

class FoodLogWidget extends StatelessWidget {
  const FoodLogWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final compact = settingsProvider.compactWidgets;

    return Consumer<FoodLogProvider>(
      builder: (context, provider, child) {
        final todayEntries = provider.todayEntries;
        final summary = provider.todaySummary;
        final goal = provider.effectiveGoal;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        // Calculate progress
        final calorieProgress = goal.targetCalories > 0
            ? (summary.totalCalories / goal.targetCalories).clamp(0.0, 1.5)
            : 0.0;
        final goalMet = summary.totalCalories >= goal.targetCalories;
        final overGoal = summary.totalCalories > goal.targetCalories * 1.1; // 10% over

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(compact ? 12 : 16),
            side: BorderSide(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 12.0 : 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    if (!compact)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                      ),
                    if (!compact) AppSpacing.gapSm,
                    if (compact)
                      Icon(
                        Icons.restaurant_menu,
                        color: Colors.green.shade600,
                        size: 18,
                      ),
                    if (compact) const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Food Today',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: compact ? 14 : null,
                        ),
                      ),
                    ),
                    // View all button - hide in compact mode
                    if (!compact)
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FoodLogScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.list, size: 16),
                        label: const Text('All'),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: compact ? 8 : 16),

                // Progress section
                Row(
                  children: [
                    // Calorie progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Count display
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '${summary.totalCalories}',
                                  style: (compact
                                          ? theme.textTheme.titleLarge
                                          : theme.textTheme.headlineMedium)
                                      ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: overGoal
                                        ? Colors.orange.shade600
                                        : goalMet
                                            ? Colors.green.shade600
                                            : colorScheme.onSurface,
                                  ),
                                ),
                                TextSpan(
                                  text: ' / ${goal.targetCalories} cal',
                                  style: (compact
                                          ? theme.textTheme.bodySmall
                                          : theme.textTheme.bodyMedium)
                                      ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: compact ? 4 : 8),
                          // Progress bar
                          ClipRRect(
                            borderRadius: BorderRadius.circular(compact ? 6 : 8),
                            child: LinearProgressIndicator(
                              value: calorieProgress.clamp(0.0, 1.0),
                              minHeight: compact ? 8 : 12,
                              backgroundColor: Colors.green.shade50,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                overGoal
                                    ? Colors.orange.shade400
                                    : goalMet
                                        ? Colors.green.shade400
                                        : Colors.green.shade300,
                              ),
                            ),
                          ),
                          // Status text and meal count - hide in compact mode
                          if (!compact) ...[
                            AppSpacing.gapXs,
                            Row(
                              children: [
                                Text(
                                  _getStatusText(summary, goal),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: overGoal
                                        ? Colors.orange.shade600
                                        : goalMet
                                            ? Colors.green.shade600
                                            : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const Spacer(),
                                // Meal count
                                Icon(
                                  Icons.lunch_dining,
                                  size: 14,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${todayEntries.length} ${todayEntries.length == 1 ? 'meal' : 'meals'}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 16),
                    // Add button - hide in compact mode
                    if (!compact)
                      _AddFoodButton(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const FoodLogScreen(),
                            ),
                          );
                        },
                      ),
                  ],
                ),

                // Quick meal type chips and prompts - hide in compact mode
                if (!compact) ...[
                  // Quick meal type chips (if entries exist today)
                  if (todayEntries.isNotEmpty) ...[
                    AppSpacing.gapMd,
                    _buildMealChips(context, provider),
                  ],

                  // No entries prompt
                  if (todayEntries.isEmpty) ...[
                    AppSpacing.gapSm,
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lightbulb_outline,
                            size: 16,
                            color: Colors.green.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Log your meals to track nutrition and build healthy eating habits',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  String _getStatusText(NutritionSummary summary, NutritionGoal goal) {
    final remaining = goal.targetCalories - summary.totalCalories;
    if (remaining <= 0) {
      if (remaining < -(goal.targetCalories * 0.1)) {
        return 'Over goal by ${-remaining} cal';
      }
      return 'Goal reached!';
    }
    return '$remaining cal remaining';
  }

  Widget _buildMealChips(BuildContext context, FoodLogProvider provider) {
    final theme = Theme.of(context);
    final todayByMeal = provider.entriesByMealType(DateTime.now());

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: MealType.values.where((type) {
        return todayByMeal[type]?.isNotEmpty ?? false;
      }).map((type) {
        final entries = todayByMeal[type]!;
        final calories = entries.fold<double>(
          0,
          (sum, e) => sum + (e.nutrition?.calories ?? 0),
        );
        return Chip(
          avatar: Text(
            type.emoji,
            style: const TextStyle(fontSize: 14),
          ),
          label: Text(
            '${type.displayName}: ${calories.round()} cal',
            style: theme.textTheme.bodySmall,
          ),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: EdgeInsets.zero,
          labelPadding: const EdgeInsets.only(right: 8),
        );
      }).toList(),
    );
  }
}

/// Animated tap-to-add button
class _AddFoodButton extends StatefulWidget {
  final VoidCallback onTap;

  const _AddFoodButton({required this.onTap});

  @override
  State<_AddFoodButton> createState() => _AddFoodButtonState();
}

class _AddFoodButtonState extends State<_AddFoodButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    _controller.forward().then((_) {
      _controller.reverse();
      widget.onTap();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.green.shade300,
                Colors.green.shade500,
              ],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.green.shade200.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                color: Colors.white,
                size: 28,
              ),
              Text(
                'Food',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
