import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/food_template.dart';
import '../models/food_entry.dart';
import '../providers/food_library_provider.dart';
import '../services/ai_service.dart';
import '../services/food_search_service.dart';
import '../widgets/food_database_search_sheet.dart';

/// Screen for managing the user's food library
class FoodLibraryScreen extends StatefulWidget {
  const FoodLibraryScreen({super.key});

  @override
  State<FoodLibraryScreen> createState() => _FoodLibraryScreenState();
}

class _FoodLibraryScreenState extends State<FoodLibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  FoodCategory? _selectedCategory;
  String _sortBy = 'name'; // 'name', 'recent', 'frequent'
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<FoodTemplate> _getFilteredTemplates(FoodLibraryProvider provider) {
    List<FoodTemplate> templates;

    // Apply favorites filter
    if (_showFavoritesOnly) {
      templates = provider.favorites;
    } else if (_selectedCategory != null) {
      // Apply category filter
      templates = provider.byCategory(_selectedCategory!);
    } else {
      templates = provider.templates;
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      templates = templates.where((t) => t.matchesSearch(_searchQuery)).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'recent':
        templates.sort((a, b) {
          if (a.lastUsed == null && b.lastUsed == null) return 0;
          if (a.lastUsed == null) return 1;
          if (b.lastUsed == null) return -1;
          return b.lastUsed!.compareTo(a.lastUsed!);
        });
        break;
      case 'frequent':
        templates.sort((a, b) => b.useCount.compareTo(a.useCount));
        break;
      case 'name':
      default:
        templates.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }

    return templates;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Library'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) => setState(() => _sortBy = value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'name',
                child: Row(
                  children: [
                    Icon(
                      Icons.sort_by_alpha,
                      color: _sortBy == 'name' ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Name'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'recent',
                child: Row(
                  children: [
                    Icon(
                      Icons.history,
                      color: _sortBy == 'recent' ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Recently Used'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'frequent',
                child: Row(
                  children: [
                    Icon(
                      Icons.trending_up,
                      color: _sortBy == 'frequent' ? colorScheme.primary : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Most Used'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<FoodLibraryProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final templates = _getFilteredTemplates(provider);

          return Column(
            children: [
              // Search bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search Food Library',
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
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // Category filter chips
              SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: _selectedCategory == null,
                      onSelected: (_) => setState(() => _selectedCategory = null),
                    ),
                    const SizedBox(width: 8),
                    ...FoodCategory.values.map((category) {
                      final count = provider.byCategory(category).length;
                      if (count == 0) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text('${category.emoji} ${category.displayName}'),
                          selected: _selectedCategory == category,
                          onSelected: (_) => setState(
                            () => _selectedCategory =
                                _selectedCategory == category ? null : category,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Results count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${templates.length} ${templates.length == 1 ? 'food' : 'foods'}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Spacer(),
                    if (provider.favorites.isNotEmpty)
                      TextButton.icon(
                        icon: Icon(
                          _showFavoritesOnly ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                        ),
                        label: Text(
                          _showFavoritesOnly
                              ? 'Show all'
                              : '${provider.favorites.length} favorites',
                        ),
                        onPressed: () {
                          setState(() {
                            _showFavoritesOnly = !_showFavoritesOnly;
                            if (_showFavoritesOnly) {
                              _selectedCategory = null; // Clear category when showing favorites
                            }
                          });
                        },
                      ),
                  ],
                ),
              ),

              // Food list
              Expanded(
                child: templates.isEmpty
                    ? _buildEmptyState(context)
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 100),
                        itemCount: templates.length,
                        itemBuilder: (context, index) {
                          final template = templates[index];
                          return _FoodTemplateCard(
                            template: template,
                            onTap: () => _showTemplateDetails(context, template),
                            onEdit: () => _showEditTemplateSheet(context, template),
                            onDelete: () => _confirmDelete(context, provider, template),
                            onToggleFavorite: () => provider.toggleFavorite(template.id),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            heroTag: 'search_online',
            onPressed: () => _showOnlineSearch(context),
            icon: const Icon(Icons.search),
            label: const Text('Search Online'),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'manual_add',
            onPressed: () => _showAddTemplateSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Manually Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    if (_searchQuery.isNotEmpty || _selectedCategory != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No foods found',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          Text(
            'Your food library is empty',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Add foods you eat often for quick logging',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddTemplateSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Add First Food'),
          ),
        ],
      ),
    );
  }

  void _showTemplateDetails(BuildContext context, FoodTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FoodTemplateDetailsSheet(template: template),
    );
  }

  void _showOnlineSearch(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => FoodDatabaseSearchSheet(
        onFoodSelected: (result) {
          // When food is selected from online search, save it to the library
          final libraryProvider = context.read<FoodLibraryProvider>();

          // Parse serving size
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

          libraryProvider.addTemplate(template);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added "${template.name}" to library'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  void _showAddTemplateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _AddEditFoodTemplateSheet(),
    );
  }

  void _showEditTemplateSheet(BuildContext context, FoodTemplate template) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _AddEditFoodTemplateSheet(template: template),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    FoodLibraryProvider provider,
    FoodTemplate template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Food?'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await provider.deleteTemplate(template.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${template.name} deleted')),
        );
      }
    }
  }
}

/// Card widget for displaying a food template
class _FoodTemplateCard extends StatelessWidget {
  final FoodTemplate template;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  const _FoodTemplateCard({
    required this.template,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Category emoji
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  template.category.emoji,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
              const SizedBox(width: 12),

              // Food info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.name,
                            style: theme.textTheme.titleSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (template.isFavorite)
                          Icon(
                            Icons.favorite,
                            size: 16,
                            color: colorScheme.error,
                          ),
                      ],
                    ),
                    if (template.brand != null)
                      Text(
                        template.brand!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _NutritionBadge(
                          value: template.nutritionPerServing.calories,
                          unit: 'cal',
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${template.nutritionPerServing.proteinGrams}g P · '
                          '${template.nutritionPerServing.carbsGrams}g C · '
                          '${template.nutritionPerServing.fatGrams}g F',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'per ${template.servingText}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'favorite':
                      onToggleFavorite();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'favorite',
                    child: Row(
                      children: [
                        Icon(
                          template.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: template.isFavorite ? colorScheme.error : null,
                        ),
                        const SizedBox(width: 8),
                        Text(template.isFavorite ? 'Unfavorite' : 'Favorite'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: colorScheme.error),
                        const SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: colorScheme.error)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NutritionBadge extends StatelessWidget {
  final int value;
  final String unit;
  final Color color;

  const _NutritionBadge({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$value $unit',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}

/// Bottom sheet showing food template details
class _FoodTemplateDetailsSheet extends StatelessWidget {
  final FoodTemplate template;

  const _FoodTemplateDetailsSheet({required this.template});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final nutrition = template.nutritionPerServing;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => SingleChildScrollView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
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

            // Header
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
                    template.category.emoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: theme.textTheme.headlineSmall,
                      ),
                      if (template.brand != null)
                        Text(
                          template.brand!,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Serving info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Serving: ${template.servingText}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Nutrition facts
            Text(
              'Nutrition Facts',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),

            // Calories
            _NutritionRow(
              label: 'Calories',
              value: '${nutrition.calories}',
              isHeader: true,
            ),
            const Divider(),

            // Macros
            _NutritionRow(
              label: 'Protein',
              value: '${nutrition.proteinGrams}g',
            ),
            _NutritionRow(
              label: 'Carbohydrates',
              value: '${nutrition.carbsGrams}g',
            ),
            _NutritionRow(
              label: '  Fiber',
              value: '${nutrition.fiberGrams ?? 0}g',
              isIndented: true,
            ),
            _NutritionRow(
              label: '  Sugar',
              value: '${nutrition.sugarGrams ?? 0}g',
              isIndented: true,
            ),
            _NutritionRow(
              label: 'Fat',
              value: '${nutrition.fatGrams}g',
            ),
            _NutritionRow(
              label: '  Saturated',
              value: '${nutrition.saturatedFatGrams ?? 0}g',
              isIndented: true,
            ),
            _NutritionRow(
              label: '  Unsaturated',
              value: '${nutrition.unsaturatedFatGrams ?? 0}g',
              isIndented: true,
            ),

            if (nutrition.sodiumMg != null ||
                nutrition.cholesterolMg != null ||
                nutrition.potassiumMg != null) ...[
              const Divider(),
              if (nutrition.sodiumMg != null)
                _NutritionRow(
                  label: 'Sodium',
                  value: '${nutrition.sodiumMg}mg',
                ),
              if (nutrition.cholesterolMg != null)
                _NutritionRow(
                  label: 'Cholesterol',
                  value: '${nutrition.cholesterolMg}mg',
                ),
              if (nutrition.potassiumMg != null)
                _NutritionRow(
                  label: 'Potassium',
                  value: '${nutrition.potassiumMg}mg',
                ),
            ],

            const SizedBox(height: 24),

            // Source info
            if (template.sourceNotes != null || template.source != NutritionSource.manual)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(template.source.emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.source.displayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (template.sourceNotes != null)
                            Text(
                              template.sourceNotes!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class _NutritionRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHeader;
  final bool isIndented;

  const _NutritionRow({
    required this.label,
    required this.value,
    this.isHeader = false,
    this.isIndented = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: isHeader
                ? theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : isIndented
                    ? theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      )
                    : theme.textTheme.bodyMedium,
          ),
          Text(
            value,
            style: isHeader
                ? theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  )
                : theme.textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet for adding or editing a food template
class _AddEditFoodTemplateSheet extends StatefulWidget {
  final FoodTemplate? template;

  const _AddEditFoodTemplateSheet({this.template});

  @override
  State<_AddEditFoodTemplateSheet> createState() => _AddEditFoodTemplateSheetState();
}

class _AddEditFoodTemplateSheetState extends State<_AddEditFoodTemplateSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _brandController;
  late TextEditingController _descriptionController;
  late TextEditingController _servingSizeController;
  late TextEditingController _caloriesController;
  late TextEditingController _proteinController;
  late TextEditingController _carbsController;
  late TextEditingController _fatController;
  late TextEditingController _fiberController;
  late TextEditingController _sugarController;
  late TextEditingController _sodiumController;
  late TextEditingController _saturatedFatController;
  late TextEditingController _transFatController;

  late FoodCategory _category;
  late ServingUnit _servingUnit;
  bool _isLoading = false;

  bool get isEditing => widget.template != null;

  @override
  void initState() {
    super.initState();
    final t = widget.template;

    _nameController = TextEditingController(text: t?.name ?? '');
    _brandController = TextEditingController(text: t?.brand ?? '');
    _descriptionController = TextEditingController(text: t?.description ?? '');
    _servingSizeController = TextEditingController(
      text: t?.defaultServingSize.toString() ?? '1',
    );
    _caloriesController = TextEditingController(
      text: t?.nutritionPerServing.calories.toString() ?? '',
    );
    _proteinController = TextEditingController(
      text: t?.nutritionPerServing.proteinGrams.toString() ?? '',
    );
    _carbsController = TextEditingController(
      text: t?.nutritionPerServing.carbsGrams.toString() ?? '',
    );
    _fatController = TextEditingController(
      text: t?.nutritionPerServing.fatGrams.toString() ?? '',
    );
    _fiberController = TextEditingController(
      text: t?.nutritionPerServing.fiberGrams?.toString() ?? '',
    );
    _sugarController = TextEditingController(
      text: t?.nutritionPerServing.sugarGrams?.toString() ?? '',
    );
    _sodiumController = TextEditingController(
      text: t?.nutritionPerServing.sodiumMg?.toString() ?? '',
    );
    _saturatedFatController = TextEditingController(
      text: t?.nutritionPerServing.saturatedFatGrams?.toString() ?? '',
    );
    _transFatController = TextEditingController(
      text: t?.nutritionPerServing.transFatGrams?.toString() ?? '',
    );

    _category = t?.category ?? FoodCategory.other;
    _servingUnit = t?.servingUnit ?? ServingUnit.serving;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _brandController.dispose();
    _descriptionController.dispose();
    _servingSizeController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sugarController.dispose();
    _sodiumController.dispose();
    _saturatedFatController.dispose();
    _transFatController.dispose();
    super.dispose();
  }

  Future<void> _estimateWithAI() async {
    final name = _nameController.text.trim();
    final brand = _brandController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a food name first')),
      );
      return;
    }

    // Check if AI service is available
    final aiService = AIService();
    if (!aiService.hasApiKey()) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Claude API key not configured. Go to Settings → AI Settings.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    try {
      final description = brand.isNotEmpty ? '$brand $name' : name;

      // Check if it's a branded product
      final searchService = FoodSearchService();
      if (searchService.containsBrandedProduct(description)) {
        // Try web search first
        final searchResult = await searchService.searchBrandedNutrition(description);
        if (searchResult.success && searchResult.nutrition != null) {
          _populateNutrition(searchResult.nutrition!);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Found verified nutrition data!')),
            );
          }
          return;
        }
      }

      // Fall back to AI estimation
      final estimate = await aiService.estimateNutrition(description);

      if (estimate != null) {
        _populateNutrition(estimate);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nutrition estimated')),
          );
        }
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not estimate nutrition')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _populateNutrition(NutritionEstimate nutrition) {
    setState(() {
      _caloriesController.text = nutrition.calories.toString();
      _proteinController.text = nutrition.proteinGrams.toString();
      _carbsController.text = nutrition.carbsGrams.toString();
      _fatController.text = nutrition.fatGrams.toString();
      if (nutrition.fiberGrams != null) {
        _fiberController.text = nutrition.fiberGrams.toString();
      }
      if (nutrition.sugarGrams != null) {
        _sugarController.text = nutrition.sugarGrams.toString();
      }
      if (nutrition.sodiumMg != null) {
        _sodiumController.text = nutrition.sodiumMg.toString();
      }
      if (nutrition.saturatedFatGrams != null) {
        _saturatedFatController.text = nutrition.saturatedFatGrams.toString();
      }
      if (nutrition.transFatGrams != null) {
        _transFatController.text = nutrition.transFatGrams.toString();
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<FoodLibraryProvider>();

    final template = FoodTemplate(
      id: widget.template?.id,
      name: _nameController.text.trim(),
      brand: _brandController.text.trim().isEmpty ? null : _brandController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      category: _category,
      nutritionPerServing: NutritionEstimate(
        calories: double.tryParse(_caloriesController.text)?.round() ?? 0,
        proteinGrams: double.tryParse(_proteinController.text)?.round() ?? 0,
        carbsGrams: double.tryParse(_carbsController.text)?.round() ?? 0,
        fatGrams: double.tryParse(_fatController.text)?.round() ?? 0,
        fiberGrams: double.tryParse(_fiberController.text)?.round(),
        sugarGrams: double.tryParse(_sugarController.text)?.round(),
        sodiumMg: double.tryParse(_sodiumController.text)?.round(),
        saturatedFatGrams: double.tryParse(_saturatedFatController.text)?.round(),
        transFatGrams: double.tryParse(_transFatController.text)?.round(),
      ),
      defaultServingSize: double.tryParse(_servingSizeController.text) ?? 1,
      servingUnit: _servingUnit,
      source: isEditing
          ? widget.template!.source
          : NutritionSource.manual,
      createdAt: widget.template?.createdAt,
      useCount: widget.template?.useCount ?? 0,
      lastUsed: widget.template?.lastUsed,
      isFavorite: widget.template?.isFavorite ?? false,
    );

    // Check for similar templates
    if (!isEditing) {
      final similar = provider.getMostSimilar(template);
      if (similar != null && similar.similarity > 0.7 && context.mounted) {
        final action = await showDialog<String>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Similar Food Found'),
            content: Text(
              'A similar food "${similar.template.displayName}" already exists. '
              'Would you like to update it or add a new entry?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, 'cancel'),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, 'update'),
                child: const Text('Update Existing'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, 'add'),
                child: const Text('Add New'),
              ),
            ],
          ),
        );

        if (action == 'cancel') return;
        if (action == 'update') {
          await provider.mergeTemplates(similar.template.id, template);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('${template.name} updated')),
            );
          }
          return;
        }
      }
    }

    if (isEditing) {
      await provider.updateTemplate(template);
    } else {
      await provider.addTemplate(template);
    }

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEditing ? '${template.name} updated' : '${template.name} added'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Form(
        key: _formKey,
        child: SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
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
              const SizedBox(height: 16),

              // Title
              Text(
                isEditing ? 'Edit Food' : 'Manually Add Food',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Food Name *',
                  hintText: 'e.g., Chicken Breast',
                ),
                validator: (value) =>
                    value?.trim().isEmpty ?? true ? 'Name is required' : null,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Brand
              TextFormField(
                controller: _brandController,
                decoration: const InputDecoration(
                  labelText: 'Brand (optional)',
                  hintText: 'e.g., Tyson',
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Category
              DropdownButtonFormField<FoodCategory>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: FoodCategory.values.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text('${category.emoji} ${category.displayName}'),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 24),

              // Serving size
              Text(
                'Serving Size',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _servingSizeController,
                      decoration: const InputDecoration(
                        labelText: 'Amount',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<ServingUnit>(
                      value: _servingUnit,
                      decoration: const InputDecoration(
                        labelText: 'Unit',
                      ),
                      items: [
                        ...ServingUnit.countUnits,
                        ...ServingUnit.weightUnits,
                        ...ServingUnit.volumeUnits,
                      ].map((unit) {
                        return DropdownMenuItem(
                          value: unit,
                          child: Text(unit.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _servingUnit = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // AI estimation button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _estimateWithAI,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_isLoading ? 'Estimating...' : 'Estimate Nutrition with AI'),
                ),
              ),
              const SizedBox(height: 24),

              // Nutrition fields
              Text(
                'Nutrition (per serving)',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),

              // Macros row 1
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _caloriesController,
                      decoration: const InputDecoration(
                        labelText: 'Calories *',
                        suffixText: 'cal',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(value!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Protein *',
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(value!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Macros row 2
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Carbs *',
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(value!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(
                        labelText: 'Fat *',
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Required';
                        if (double.tryParse(value!) == null) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Fat breakdown (optional)
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _saturatedFatController,
                      decoration: const InputDecoration(
                        labelText: 'Saturated Fat',
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _transFatController,
                      decoration: const InputDecoration(
                        labelText: 'Trans Fat',
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Other nutrients
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _fiberController,
                      decoration: const InputDecoration(
                        labelText: 'Fiber',
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sugarController,
                      decoration: const InputDecoration(
                        labelText: 'Sugar',
                        suffixText: 'g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _sodiumController,
                decoration: const InputDecoration(
                  labelText: 'Sodium',
                  suffixText: 'mg',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 32),

              // Save button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: Text(isEditing ? 'Save Changes' : 'Add to Library'),
                ),
              ),
              const SizedBox(height: 16),

              // Cancel button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
