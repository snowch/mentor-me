/// Food database search sheet widget
///
/// Provides unified search across Open Food Facts and CoFID databases
/// with support for barcode lookup and category browsing.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../models/food_entry.dart';
import '../models/food_template.dart';
import '../providers/food_library_provider.dart';
import '../services/ai_service.dart';
import '../services/food_database_service.dart';
import '../services/food_search_service.dart';
import '../theme/app_spacing.dart';

/// Result returned when user selects a food
class FoodSelectionResult {
  final String name;
  final String? brand;
  final NutritionEstimate nutrition;
  final String? servingSize;
  final FoodDataSource source;
  final double confidence;
  final String? barcode;
  final String? imageUrl;

  const FoodSelectionResult({
    required this.name,
    this.brand,
    required this.nutrition,
    this.servingSize,
    required this.source,
    required this.confidence,
    this.barcode,
    this.imageUrl,
  });

  factory FoodSelectionResult.fromDatabaseResult(FoodDatabaseResult result) {
    return FoodSelectionResult(
      name: result.productName ?? 'Unknown',
      brand: result.brand,
      nutrition: result.nutrition!,
      servingSize: result.servingSize,
      source: result.source ?? FoodDataSource.manual,
      confidence: result.confidence,
      barcode: result.barcode,
      imageUrl: result.imageUrl,
    );
  }
}

/// Bottom sheet for searching food databases
class FoodDatabaseSearchSheet extends StatefulWidget {
  final Function(FoodSelectionResult) onFoodSelected;
  final String? initialQuery;

  const FoodDatabaseSearchSheet({
    super.key,
    required this.onFoodSelected,
    this.initialQuery,
  });

  @override
  State<FoodDatabaseSearchSheet> createState() => _FoodDatabaseSearchSheetState();
}

class _FoodDatabaseSearchSheetState extends State<FoodDatabaseSearchSheet>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _foodDbService = FoodDatabaseService();
  final _searchService = FoodSearchService();

  late TabController _tabController;
  List<FoodDatabaseResult> _searchResults = [];
  List<FoodDatabaseResult> _categoryFoods = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isSearching = false;
  bool _isLoadingCategories = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Add listener to update clear button visibility when text changes
    _searchController.addListener(_onSearchTextChanged);
    // Pre-populate search if initial query provided
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
    }
    _initializeServices();
  }

  void _onSearchTextChanged() {
    // Trigger rebuild to show/hide clear button
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _barcodeController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    setState(() => _isLoadingCategories = true);
    try {
      await _foodDbService.initialize();
      await _searchService.initialize();
      await _loadCategories();
      // Auto-search if initial query was provided
      if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
        await _performSearch(widget.initialQuery!);
      }
    } catch (e) {
      setState(() => _errorMessage = 'Failed to initialize: $e');
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _loadCategories() async {
    // Use predefined categories for better UX
    // Note: Could dynamically load from _foodDbService.getCommonFoods() if needed
    setState(() {
      _categories = [
        'Meat & Poultry',
        'Fish & Seafood',
        'Dairy & Eggs',
        'Bread & Cereals',
        'Vegetables',
        'Fruits',
        'Beverages',
        'Prepared Foods',
        'Snacks & Sweets',
      ];
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final results = await _searchService.searchWithFallback(
        query,
        limit: 20,
        includeAiFallback: false, // Don't use AI in search, let user choose
      );

      setState(() {
        _searchResults = results.map((r) => FoodDatabaseResult.success(
          source: r.source ?? FoodDataSource.openFoodFacts,
          productName: r.productName ?? query,
          brand: r.brand,
          barcode: r.barcode,
          nutrition: r.nutrition!,
          servingSize: r.servingSize,
          confidence: r.confidence,
          imageUrl: r.imageUrl,
        )).toList();
      });
    } catch (e) {
      setState(() => _errorMessage = 'Search failed: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _searchBarcode(String barcode) async {
    if (barcode.trim().isEmpty) return;

    // Validate barcode format
    if (!_searchService.isValidBarcode(barcode.trim())) {
      setState(() => _errorMessage = 'Invalid barcode format. Expected 8, 12, or 13 digits.');
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final result = await _searchService.searchByBarcode(barcode.trim());

      if (result.success && result.nutrition != null) {
        // Auto-select if found
        widget.onFoodSelected(FoodSelectionResult(
          name: result.productName ?? 'Unknown Product',
          brand: result.brand,
          nutrition: result.nutrition!,
          servingSize: result.servingSize,
          source: result.source ?? FoodDataSource.openFoodFacts,
          confidence: result.confidence,
          barcode: result.barcode,
          imageUrl: result.imageUrl,
        ));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _errorMessage = 'Product not found for barcode: $barcode');
      }
    } catch (e) {
      setState(() => _errorMessage = 'Barcode search failed: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _loadCategoryFoods(String category) async {
    setState(() {
      _selectedCategory = category;
      _isSearching = true;
    });

    try {
      // Search for foods matching the category
      final query = _getCategorySearchTerms(category);
      final results = await _foodDbService.searchByName(query, limit: 30, includeOpenFoodFacts: false);

      setState(() {
        _categoryFoods = results;
      });
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load category: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  String _getCategorySearchTerms(String category) {
    switch (category) {
      case 'Meat & Poultry':
        return 'chicken beef pork lamb';
      case 'Fish & Seafood':
        return 'fish salmon cod prawns';
      case 'Dairy & Eggs':
        return 'milk cheese egg yogurt';
      case 'Bread & Cereals':
        return 'bread rice pasta cereal';
      case 'Vegetables':
        return 'vegetable potato carrot peas';
      case 'Fruits':
        return 'apple banana orange fruit';
      case 'Beverages':
        return 'tea coffee juice drink';
      case 'Prepared Foods':
        return 'pie curry pizza sandwich';
      case 'Snacks & Sweets':
        return 'biscuit chocolate crisps cake';
      default:
        return category;
    }
  }

  void _selectFood(FoodDatabaseResult result) {
    if (result.nutrition == null) return;

    widget.onFoodSelected(FoodSelectionResult.fromDatabaseResult(result));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
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
                  Icon(Icons.search, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Search Food Database',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Tab bar
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(icon: Icon(Icons.search), text: 'Search'),
                Tab(icon: Icon(Icons.qr_code), text: 'Barcode'),
                Tab(icon: Icon(Icons.category), text: 'Browse'),
              ],
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSearchTab(theme, scrollController),
                  _buildBarcodeTab(theme),
                  _buildBrowseTab(theme, scrollController),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchTab(ThemeData theme, ScrollController scrollController) {
    return Column(
      children: [
        // Search field
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search foods (e.g., "Tesco chicken breast")',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchResults = []);
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onSubmitted: _performSearch,
            textInputAction: TextInputAction.search,
          ),
        ),

        // Source info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              _buildSourceBadge(theme, FoodDataSource.openFoodFacts),
              const SizedBox(width: 8),
              _buildSourceBadge(theme, FoodDataSource.cofid),
            ],
          ),
        ),

        AppSpacing.gapVerticalSm,

        // Error message
        if (_errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: theme.colorScheme.onErrorContainer),
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Results
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _searchResults.isEmpty
                  ? _buildEmptySearchState(theme)
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 16,
                        bottom: 100, // Extra padding for bottom nav
                      ),
                      // +1 for AI estimation footer
                      itemCount: _searchResults.length + 1,
                      itemBuilder: (context, index) {
                        // Last item: AI estimation option
                        if (index == _searchResults.length) {
                          return _buildAIEstimateFooter(theme);
                        }
                        return _buildFoodResultCard(theme, _searchResults[index]);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildBarcodeTab(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Camera scan button (not available on web)
          if (!kIsWeb) ...[
            FilledButton.icon(
              onPressed: _isSearching ? null : () => _openBarcodeScanner(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Scan with Camera'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
              ),
            ),
            AppSpacing.gapVerticalMd,
            Row(
              children: [
                Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ),
                Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
              ],
            ),
            AppSpacing.gapVerticalMd,
          ],

          // Info card for manual entry
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Icon(
                    Icons.keyboard,
                    size: 40,
                    color: theme.colorScheme.primary,
                  ),
                  AppSpacing.gapVerticalSm,
                  Text(
                    'Enter Barcode Manually',
                    style: theme.textTheme.titleMedium,
                  ),
                  AppSpacing.gapVerticalXs,
                  Text(
                    'Type the barcode number from the product packaging.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

          AppSpacing.gapVerticalMd,

          // Barcode input
          TextField(
            controller: _barcodeController,
            maxLength: 13,
            decoration: InputDecoration(
              hintText: 'Enter barcode (8, 12, or 13 digits)',
              prefixIcon: const Icon(Icons.qr_code),
              counterText: '', // Hide the counter
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            keyboardType: TextInputType.number,
            onSubmitted: _searchBarcode,
          ),

          AppSpacing.gapVerticalMd,

          FilledButton.tonalIcon(
            onPressed: _isSearching
                ? null
                : () => _searchBarcode(_barcodeController.text),
            icon: _isSearching
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.search),
            label: Text(_isSearching ? 'Searching...' : 'Look Up Barcode'),
          ),

          AppSpacing.gapVerticalMd,

          // Error message
          if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.onErrorContainer),
              ),
            ),

          const Spacer(),

          // Source attribution
          Text(
            'Powered by Open Food Facts',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  /// Opens the barcode scanner camera
  Future<void> _openBarcodeScanner(BuildContext context) async {
    final scannedBarcode = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const _BarcodeScannerSheet(),
    );

    if (scannedBarcode != null && scannedBarcode.isNotEmpty) {
      _barcodeController.text = scannedBarcode;
      await _searchBarcode(scannedBarcode);
    }
  }

  Widget _buildBrowseTab(ThemeData theme, ScrollController scrollController) {
    if (_isLoadingCategories) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Category chips
        SizedBox(
          height: 48,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              final isSelected = _selectedCategory == category;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category),
                  selected: isSelected,
                  onSelected: (_) => _loadCategoryFoods(category),
                ),
              );
            },
          ),
        ),

        AppSpacing.gapVerticalSm,

        // Category info
        if (_selectedCategory != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: theme.colorScheme.outline),
                const SizedBox(width: 4),
                Text(
                  'UK foods from CoFID database (per 100g)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),

        // Foods list
        Expanded(
          child: _isSearching
              ? const Center(child: CircularProgressIndicator())
              : _selectedCategory == null
                  ? _buildCategoryPrompt(theme)
                  : _categoryFoods.isEmpty
                      ? Center(
                          child: Text(
                            'No foods found in this category',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.outline,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            top: 16,
                            bottom: 100, // Extra padding for bottom nav
                          ),
                          itemCount: _categoryFoods.length,
                          itemBuilder: (context, index) =>
                              _buildFoodResultCard(theme, _categoryFoods[index]),
                        ),
        ),
      ],
    );
  }

  Widget _buildEmptySearchState(ThemeData theme) {
    final hasSearchQuery = _searchController.text.trim().isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasSearchQuery ? Icons.search_off : Icons.search,
              size: 64,
              color: theme.colorScheme.outlineVariant,
            ),
            AppSpacing.gapVerticalMd,
            Text(
              hasSearchQuery ? 'No results found' : 'Search for foods',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            AppSpacing.gapVerticalSm,
            Text(
              hasSearchQuery
                  ? 'Try a different search or use AI to estimate nutrition.'
                  : 'Search UK branded products and common foods\nfor accurate nutrition information.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            // AI estimate button when no results
            if (hasSearchQuery) ...[
              AppSpacing.gapVerticalLg,
              FilledButton.tonalIcon(
                onPressed: _estimateWithAI,
                icon: const Icon(Icons.auto_awesome),
                label: Text('Estimate "${_searchController.text.trim()}" with AI'),
              ),
              AppSpacing.gapVerticalSm,
              Text(
                'AI estimates are approximate',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Footer shown at bottom of search results to allow AI estimation
  Widget _buildAIEstimateFooter(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.search_off,
                color: theme.colorScheme.outline,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Can't find what you're looking for?",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
          AppSpacing.gapVerticalMd,
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: _estimateWithAI,
              icon: const Icon(Icons.auto_awesome),
              label: Text('Estimate "${_searchController.text.trim()}" with AI'),
            ),
          ),
          AppSpacing.gapVerticalSm,
          Text(
            'AI estimates are approximate and may vary',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPrompt(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.category,
              size: 64,
              color: theme.colorScheme.outlineVariant,
            ),
            AppSpacing.gapVerticalMd,
            Text(
              'Select a category',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            AppSpacing.gapVerticalSm,
            Text(
              'Browse common UK foods from the\nofficial CoFID database.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodResultCard(ThemeData theme, FoodDatabaseResult result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _selectFood(result),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Food image or icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: result.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          result.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.restaurant,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.restaurant,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
              ),

              const SizedBox(width: 12),

              // Food details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and brand
                    Text(
                      result.productName ?? 'Unknown',
                      style: theme.textTheme.titleSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (result.brand != null)
                      Text(
                        result.brand!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),

                    AppSpacing.gapVerticalXs,

                    // Nutrition summary
                    if (result.nutrition != null)
                      Text(
                        '${result.nutrition!.calories} cal · ${result.nutrition!.proteinGrams}g P · ${result.nutrition!.carbsGrams}g C · ${result.nutrition!.fatGrams}g F',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),

                    AppSpacing.gapVerticalXs,

                    // Source and serving
                    Row(
                      children: [
                        if (result.source != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: _getSourceColor(theme, result.source!),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${result.source!.emoji} ${result.source!.displayName}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (result.servingSize != null)
                          Expanded(
                            child: Text(
                              result.servingSize!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.outline,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action buttons column
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Save to library button
                  IconButton(
                    icon: const Icon(Icons.bookmark_add_outlined),
                    tooltip: 'Save to Library',
                    onPressed: result.nutrition != null
                        ? () => _saveToLibrary(context, result)
                        : null,
                    iconSize: 20,
                    visualDensity: VisualDensity.compact,
                  ),
                  // Select/log button
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Save a food result directly to the library
  Future<void> _saveToLibrary(BuildContext context, FoodDatabaseResult result) async {
    if (result.nutrition == null) return;

    final libraryProvider = context.read<FoodLibraryProvider>();
    final theme = Theme.of(context);

    // Determine food category based on source or default to 'other'
    const category = FoodCategory.other;

    // Determine nutrition source - all external database sources map to imported
    const nutritionSource = NutritionSource.imported;

    final template = FoodTemplate(
      name: result.productName ?? 'Unknown',
      brand: result.brand,
      category: category,
      nutritionPerServing: result.nutrition!,
      defaultServingSize: 1,
      servingUnit: ServingUnit.serving,
      servingDescription: result.servingSize,
      source: nutritionSource,
      sourceNotes: result.source?.displayName,
      barcode: result.barcode,
      imagePath: result.imageUrl,
    );

    // Check for similar templates
    final similar = libraryProvider.getMostSimilar(template);
    if (similar != null && similar.similarity > 0.7) {
      // Show dialog to handle duplicate
      final action = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Similar Food Found'),
          content: Text(
            'A similar food "${similar.template.name}" already exists in your library. '
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

      if (action == 'cancel' || action == null) return;

      if (action == 'update') {
        await libraryProvider.mergeTemplates(similar.template.id, template);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated "${similar.template.name}" in library'),
              backgroundColor: theme.colorScheme.primary,
            ),
          );
        }
        return;
      }
    }

    // Add new template
    await libraryProvider.addTemplate(template);

    if (context.mounted) {
      // Show simple toast feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved "${template.name}" to library'),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Estimate nutrition using AI when food not found in database
  Future<void> _estimateWithAI() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    // Check if AI service is available
    final aiService = AIService();
    if (!aiService.hasApiKey()) {
      setState(() {
        _errorMessage = 'Claude API key not configured. Go to Settings → AI Settings to add your API key.';
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      final response = await aiService.estimateNutrition(query);

      if (response != null) {
        // Create a result from AI estimate
        widget.onFoodSelected(FoodSelectionResult(
          name: query,
          nutrition: response,
          source: FoodDataSource.aiEstimated,
          confidence: 0.7,
        ));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() => _errorMessage = 'AI could not estimate nutrition for "$query"');
      }
    } catch (e) {
      setState(() => _errorMessage = 'AI estimation failed: $e');
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Widget _buildSourceBadge(ThemeData theme, FoodDataSource source) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getSourceColor(theme, source).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getSourceColor(theme, source)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(source.emoji),
          const SizedBox(width: 4),
          Text(
            source.displayName,
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getSourceColor(theme, source),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSourceColor(ThemeData theme, FoodDataSource source) {
    switch (source) {
      case FoodDataSource.openFoodFacts:
        return Colors.orange.shade700;
      case FoodDataSource.cofid:
        return Colors.blue.shade700;
      case FoodDataSource.aiEstimated:
        return Colors.purple.shade700;
      case FoodDataSource.manual:
        return Colors.grey.shade600;
      case FoodDataSource.cached:
        return Colors.green.shade700;
    }
  }
}

/// Barcode scanner sheet using device camera
class _BarcodeScannerSheet extends StatefulWidget {
  const _BarcodeScannerSheet();

  @override
  State<_BarcodeScannerSheet> createState() => _BarcodeScannerSheetState();
}

class _BarcodeScannerSheetState extends State<_BarcodeScannerSheet> {
  MobileScannerController? _controller;
  bool _hasScanned = false;
  bool _hasError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    try {
      _controller = MobileScannerController(
        detectionSpeed: DetectionSpeed.normal,
        facing: CameraFacing.back,
        torchEnabled: false,
      );
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Failed to initialize camera: $e';
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onBarcodeDetected(BarcodeCapture capture) {
    if (_hasScanned) return; // Prevent multiple scans

    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final barcode = barcodes.first;
    final value = barcode.rawValue;

    if (value != null && value.isNotEmpty) {
      setState(() => _hasScanned = true);
      Navigator.pop(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(Icons.qr_code_scanner, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text('Scan Barcode', style: theme.textTheme.titleLarge),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Scanner or error
          Expanded(
            child: _hasError
                ? _buildErrorState(theme)
                : _controller == null
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          // Camera preview
                          MobileScanner(
                            controller: _controller!,
                            onDetect: _onBarcodeDetected,
                            errorBuilder: (context, error, child) {
                              return _buildCameraError(theme, error);
                            },
                          ),

                          // Scan overlay
                          _buildScanOverlay(theme),

                          // Torch toggle
                          Positioned(
                            bottom: 32,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Torch button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: ValueListenableBuilder<MobileScannerState>(
                                    valueListenable: _controller!,
                                    builder: (context, state, child) {
                                      return IconButton(
                                        icon: Icon(
                                          state.torchState == TorchState.on
                                              ? Icons.flash_on
                                              : Icons.flash_off,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => _controller!.toggleTorch(),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Camera switch button
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.cameraswitch,
                                      color: Colors.white,
                                    ),
                                    onPressed: () => _controller!.switchCamera(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
          ),

          // Instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Point the camera at a barcode on food packaging',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanOverlay(ThemeData theme) {
    return Center(
      child: Container(
        width: 280,
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.primary,
            width: 3,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            // Corner accents
            Positioned(
              top: -3,
              left: -3,
              child: _buildCorner(theme, 0),
            ),
            Positioned(
              top: -3,
              right: -3,
              child: _buildCorner(theme, 90),
            ),
            Positioned(
              bottom: -3,
              right: -3,
              child: _buildCorner(theme, 180),
            ),
            Positioned(
              bottom: -3,
              left: -3,
              child: _buildCorner(theme, 270),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(ThemeData theme, double rotation) {
    return Transform.rotate(
      angle: rotation * 3.14159 / 180,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: theme.colorScheme.primary, width: 4),
            left: BorderSide(color: theme.colorScheme.primary, width: 4),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Camera Error',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unable to access camera',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              child: const Text('Enter Barcode Manually'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraError(ThemeData theme, MobileScannerException error) {
    String message;
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        message = 'Camera permission denied. Please enable camera access in settings.';
        break;
      case MobileScannerErrorCode.unsupported:
        message = 'Camera not supported on this device.';
        break;
      default:
        message = 'Camera error: ${error.errorDetails?.message ?? "Unknown error"}';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.no_photography,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            FilledButton.tonal(
              onPressed: () => Navigator.pop(context),
              child: const Text('Enter Barcode Manually'),
            ),
          ],
        ),
      ),
    );
  }
}
