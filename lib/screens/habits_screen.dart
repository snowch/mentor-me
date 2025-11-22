import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/habit.dart';
import '../providers/habit_provider.dart';
import '../widgets/habit_card.dart';
import '../widgets/add_habit_dialog.dart';
import '../constants/app_strings.dart';

class HabitsScreen extends StatelessWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final habitProvider = context.watch<HabitProvider>();
    final allHabits = habitProvider.habits;

    // Separate habits by status (sorted by sortOrder)
    final activeHabits = habitProvider.getHabitsByStatus(HabitStatus.active);
    final backlogHabits = habitProvider.getHabitsByStatus(HabitStatus.backlog);
    final completedHabits = habitProvider.getHabitsByStatus(HabitStatus.completed);

    // Today's tracking for active habits only
    final todayHabits = activeHabits.where((h) => !h.isCompletedToday).toList();
    final completedToday = activeHabits.where((h) => h.isCompletedToday).toList();

    return Scaffold(
      body: habitProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : allHabits.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppStrings.noHabitsYet,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        AppStrings.createFirstHabitBuildConsistency,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Summary card (for active habits only)
                    if (activeHabits.isNotEmpty) ...[
                      Card(
                        elevation: 0,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildStat(
                                context,
                                Icons.check_circle,
                                '${completedToday.length}',
                                AppStrings.completed,
                                Colors.green,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.1),
                              ),
                              _buildStat(
                                context,
                                Icons.radio_button_unchecked,
                                '${todayHabits.length}',
                                AppStrings.remaining,
                                Theme.of(context).colorScheme.primary,
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.1),
                              ),
                              _buildStat(
                                context,
                                Icons.local_fire_department,
                                '${activeHabits.length}',
                                AppStrings.active,
                                Colors.orange,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Active Habits section (max 2)
                    Row(
                      children: [
                        Text(
                          AppStrings.activeHabits,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${activeHabits.length}/2',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppStrings.focusOnActiveHabits,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    const SizedBox(height: 12),

                    if (activeHabits.isEmpty)
                      Card(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            AppStrings.noActiveHabitsAddOrMove,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ),
                      )
                    else ...[
                      // Active habits (reorderable + drag target for backlog items)
                      _buildDragTarget(
                        context,
                        habitProvider,
                        HabitStatus.active,
                        activeHabits,
                      ),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 24),

                    // Backlog section
                    if (backlogHabits.isNotEmpty) ...[
                      Text(
                        AppStrings.backlog,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppStrings.habitsYourePlanningLater,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 12),
                      _buildDragTarget(
                        context,
                        habitProvider,
                        HabitStatus.backlog,
                        backlogHabits,
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Completed section (collapsible)
                    if (completedHabits.isNotEmpty) ...[
                      ExpansionTile(
                        title: Text(
                          AppStrings.establishedRoutinesCount(completedHabits.length),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        initiallyExpanded: false,
                        children: completedHabits.map((habit) => HabitCard(habit: habit)).toList(),
                      ),
                    ],
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'habits_fab',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AddHabitDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: Text(AppStrings.add + ' ' + AppStrings.habit),
      ),
    );
  }

  Widget _buildDragTarget(
    BuildContext context,
    HabitProvider habitProvider,
    HabitStatus status,
    List<Habit> habits,
  ) {
    return DragTarget<Habit>(
      onWillAcceptWithDetails: (details) {
        // Always accept for reordering within same section
        if (details.data.status == status) return true;

        // For cross-section moves, check limits
        if (status == HabitStatus.active) {
          final activeCount = habitProvider.getHabitsByStatus(HabitStatus.active).length;
          return activeCount < 2;
        }
        return true;
      },
      onAcceptWithDetails: (details) async {
        final draggedHabit = details.data;

        if (draggedHabit.status == status) {
          // Reordering within same section - already handled by position
          // This shouldn't happen as we handle it in onMove
        } else {
          // Cross-section move
          // Capture messenger before async operation to avoid context issues
          final messenger = ScaffoldMessenger.of(context);
          final habitTitle = draggedHabit.title;
          final statusName = status == HabitStatus.active ? "Active" : "Backlog";

          try {
            await habitProvider.moveHabitToStatus(
              draggedHabit.id,
              status,
              habits.length, // Add to end
            );
            messenger.showSnackBar(
              SnackBar(
                content: Text('Moved "$habitTitle" to $statusName'),
                duration: const Duration(seconds: 2),
              ),
            );
          } catch (e) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(e.toString().replaceAll('Exception: ', '')),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        final isDraggingFromDifferentSection = candidateData.isNotEmpty &&
            candidateData.first?.status != status;

        return Container(
          decoration: isHighlighted && isDraggingFromDifferentSection
              ? BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.1),
                )
              : null,
          padding: isHighlighted && isDraggingFromDifferentSection ? const EdgeInsets.all(8) : null,
          child: habits.isEmpty
              ? (isHighlighted && isDraggingFromDifferentSection
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Drop here to move to ${status == HabitStatus.active ? "Active" : "Backlog"}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : const SizedBox.shrink())
              : _HabitDragList(
                  habits: habits,
                  status: status,
                  habitProvider: habitProvider,
                ),
        );
      },
    );
  }

  Widget _buildStat(BuildContext context, IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
          ),
        ],
      ),
    );
  }
}

class _HabitDragList extends StatefulWidget {
  final List<Habit> habits;
  final HabitStatus status;
  final HabitProvider habitProvider;

  const _HabitDragList({
    required this.habits,
    required this.status,
    required this.habitProvider,
  });

  @override
  State<_HabitDragList> createState() => _HabitDragListState();
}

class _HabitDragListState extends State<_HabitDragList> {
  int? _hoveredIndex;
  String? _draggingHabitId;

  @override
  Widget build(BuildContext context) {
    return DragTarget<Habit>(
      onWillAcceptWithDetails: (details) {
        // Accept items from same section for reordering
        return details.data.status == widget.status;
      },
      onMove: (details) {
        // Calculate hover index based on position
        if (details.data.status == widget.status) {
          setState(() {
            _draggingHabitId = details.data.id;
            // Simple calculation: each card is roughly 80-100px
            // We'll refine this with more precise measurements if needed
            final estimatedCardHeight = 90.0;
            final index = (details.offset.dy / estimatedCardHeight).floor();
            _hoveredIndex = index.clamp(0, widget.habits.length);
          });
        }
      },
      onLeave: (data) {
        setState(() {
          _hoveredIndex = null;
          _draggingHabitId = null;
        });
      },
      onAcceptWithDetails: (details) async {
        if (details.data.status == widget.status && _hoveredIndex != null) {
          final draggedHabit = details.data;
          final oldIndex = widget.habits.indexWhere((h) => h.id == draggedHabit.id);

          if (oldIndex != -1 && oldIndex != _hoveredIndex) {
            var newIndex = _hoveredIndex!;
            // Adjust if dragging down
            if (newIndex > oldIndex) {
              newIndex -= 1;
            }
            await widget.habitProvider.reorderHabits(widget.status, oldIndex, newIndex);
          }
        }

        setState(() {
          _hoveredIndex = null;
          _draggingHabitId = null;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: widget.habits.length + (_hoveredIndex != null ? 1 : 0),
          itemBuilder: (context, index) {
            // Show insertion indicator at hover position
            if (_hoveredIndex != null && index == _hoveredIndex) {
              return Container(
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }

            // Adjust index if we've inserted the indicator
            final habitIndex = _hoveredIndex != null && index > _hoveredIndex! ? index - 1 : index;
            if (habitIndex >= widget.habits.length) return const SizedBox.shrink();

            final habit = widget.habits[habitIndex];
            final isDragging = habit.id == _draggingHabitId;

            return LongPressDraggable<Habit>(
              key: ValueKey(habit.id),
              data: habit,
              feedback: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width - 32,
                  child: Opacity(
                    opacity: 0.8,
                    child: HabitCard(habit: habit),
                  ),
                ),
              ),
              childWhenDragging: Opacity(
                opacity: 0.3,
                child: HabitCard(habit: habit),
              ),
              child: Opacity(
                opacity: isDragging ? 0.5 : 1.0,
                child: HabitCard(habit: habit),
              ),
            );
          },
        );
      },
    );
  }
}