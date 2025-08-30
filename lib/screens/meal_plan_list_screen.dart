import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../models/meal_slot.dart';
import '../services/meal_plan_service.dart';
import '../services/meal_slot_service.dart';
import '../utils/fade_page_route.dart';
import '../widgets/meal_plan_form_dialog.dart';
import 'meal_plan_screen.dart';

/// Screen for listing and managing meal plans
class MealPlanListScreen extends StatefulWidget {
  /// Optional family ID for filtering meal plans
  final String? familyId;

  const MealPlanListScreen({super.key, this.familyId});

  @override
  State<MealPlanListScreen> createState() => _MealPlanListScreenState();
}

class _MealPlanListScreenState extends State<MealPlanListScreen> {
  final MealPlanService _mealPlanService = MealPlanService();
  final MealSlotService _mealSlotService = MealSlotService();

  List<MealPlan> _mealPlans = [];
  List<MealSlot> _availableMealSlots = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _filterType = 'all'; // all, active, templates

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Load meal plans and meal slots
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Use a default family ID if none is provided
      final familyId = widget.familyId ?? 'default_family';

      // Load meal plans and meal slots in parallel
      final results = await Future.wait([
        _mealPlanService.getMealPlans(familyId: widget.familyId),
        _mealSlotService.getFamilyMealSlots(familyId),
      ]);

      setState(() {
        _mealPlans = results[0] as List<MealPlan>;
        _availableMealSlots = results[1] as List<MealSlot>;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to load meal plans: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Get filtered meal plans based on search and filter criteria
  List<MealPlan> get _filteredMealPlans {
    var filtered = _mealPlans.where((plan) {
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!plan.name.toLowerCase().contains(query)) {
          return false;
        }
      }

      // Apply type filter
      switch (_filterType) {
        case 'active':
          return !plan.isTemplate && plan.isCurrentlyActive;
        case 'templates':
          return plan.isTemplate;
        case 'all':
        default:
          return true;
      }
    }).toList();

    // Sort by updated date (most recent first)
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return filtered;
  }

  /// Handle creating a new meal plan
  Future<void> _createMealPlan() async {
    // Use a default family ID if none is provided
    final familyId = widget.familyId ?? 'default_family';

    final newMealPlan = await showMealPlanFormDialog(
      context: context,
      availableMealSlots: _availableMealSlots,
      familyId: familyId,
      userId: 'current_user', // TODO: Get from auth service
    );

    if (newMealPlan != null) {
      try {
        final savedMealPlan = await _mealPlanService.createMealPlan(
          newMealPlan,
        );

        setState(() {
          _mealPlans.add(savedMealPlan);
        });

        _showSuccessSnackBar('Meal plan created successfully');

        // Navigate to the new meal plan with fade transition
        if (mounted) {
          FadeNavigation.push(
            context,
            MealPlanScreen(mealPlanId: savedMealPlan.id, familyId: familyId),
          );
        }
      } catch (e) {
        _showErrorSnackBar('Failed to create meal plan: ${e.toString()}');
      }
    }
  }

  /// Handle editing an existing meal plan
  Future<void> _editMealPlan(MealPlan mealPlan) async {
    // Use a default family ID if none is provided
    final familyId = widget.familyId ?? 'default_family';

    final updatedMealPlan = await showMealPlanFormDialog(
      context: context,
      existingMealPlan: mealPlan,
      availableMealSlots: _availableMealSlots,
      familyId: familyId,
      userId: 'current_user', // TODO: Get from auth service
    );

    if (updatedMealPlan != null) {
      try {
        final savedMealPlan = await _mealPlanService.updateMealPlan(
          mealPlan.id,
          updatedMealPlan,
        );

        setState(() {
          final index = _mealPlans.indexWhere((p) => p.id == mealPlan.id);
          if (index != -1) {
            _mealPlans[index] = savedMealPlan;
          }
        });

        _showSuccessSnackBar('Meal plan updated successfully');
      } catch (e) {
        _showErrorSnackBar('Failed to update meal plan: ${e.toString()}');
      }
    }
  }

  /// Handle deleting a meal plan
  Future<void> _deleteMealPlan(MealPlan mealPlan) async {
    final confirmed = await _showDeleteConfirmationDialog(mealPlan);
    if (!confirmed) return;

    try {
      await _mealPlanService.deleteMealPlan(mealPlan.id);

      setState(() {
        _mealPlans.removeWhere((p) => p.id == mealPlan.id);
      });

      _showSuccessSnackBar('Meal plan deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete meal plan: ${e.toString()}');
    }
  }

  /// Show delete confirmation dialog
  Future<bool> _showDeleteConfirmationDialog(MealPlan mealPlan) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Meal Plan'),
            content: Text(
              'Are you sure you want to delete "${mealPlan.name}"? This action cannot be undone.',
            ),
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
        ) ??
        false;
  }

  /// Navigate to meal plan detail screen
  void _openMealPlan(MealPlan mealPlan) {
    // Use a default family ID if none is provided
    final familyId = widget.familyId ?? 'default_family';

    FadeNavigation.push(
      context,
      MealPlanScreen(mealPlanId: mealPlan.id, familyId: familyId),
    );
  }

  /// Show error snackbar
  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  /// Show success snackbar
  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Meal Plans'),
      actions: [
        IconButton(
          onPressed: _loadData,
          icon: const Icon(Icons.refresh),
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  /// Build floating action button
  Widget _buildFloatingActionButton() {
    return FloatingActionButton(
      onPressed: _createMealPlan,
      tooltip: 'Create meal plan',
      child: const Icon(Icons.add),
    );
  }

  /// Build main body
  Widget _buildBody() {
    return Column(
      children: [
        // Search and filter section
        _buildSearchAndFilter(),

        // Meal plans list
        Expanded(
          child: _filteredMealPlans.isEmpty
              ? _buildEmptyState()
              : _buildMealPlansList(),
        ),
      ],
    );
  }

  /// Build search and filter section
  Widget _buildSearchAndFilter() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          // Search bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search meal plans...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      icon: const Icon(Icons.clear),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              filled: true,
              fillColor: colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),

          const SizedBox(height: 12.0),

          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('all', 'All Plans'),
                const SizedBox(width: 8.0),
                _buildFilterChip('active', 'Active'),
                const SizedBox(width: 8.0),
                _buildFilterChip('templates', 'Templates'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build filter chip
  Widget _buildFilterChip(String value, String label) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = _filterType == value;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        setState(() {
          _filterType = value;
        });
      },
      backgroundColor: colorScheme.surfaceContainerLow,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.onPrimaryContainer,
      labelStyle: TextStyle(
        color: isSelected
            ? colorScheme.onPrimaryContainer
            : colorScheme.onSurface,
      ),
    );
  }

  /// Build empty state
  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    String message;
    String subtitle;
    IconData icon;

    if (_searchQuery.isNotEmpty) {
      message = 'No meal plans found';
      subtitle = 'Try adjusting your search or filters';
      icon = Icons.search_off;
    } else if (_filterType == 'active') {
      message = 'No active meal plans';
      subtitle = 'Create a new meal plan to get started';
      icon = Icons.calendar_today;
    } else if (_filterType == 'templates') {
      message = 'No templates saved';
      subtitle = 'Save a meal plan as a template to reuse it';
      icon = Icons.bookmark_border;
    } else {
      message = 'No meal plans yet';
      subtitle = 'Create your first meal plan to get started';
      icon = Icons.restaurant_menu;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64.0,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16.0),
          Text(
            message,
            style: textTheme.titleLarge?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            subtitle,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isEmpty && _filterType == 'all') ...[
            const SizedBox(height: 24.0),
            ElevatedButton.icon(
              onPressed: _createMealPlan,
              icon: const Icon(Icons.add),
              label: const Text('Create Meal Plan'),
            ),
          ],
        ],
      ),
    );
  }

  /// Build meal plans list
  Widget _buildMealPlansList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredMealPlans.length,
      itemBuilder: (context, index) {
        final mealPlan = _filteredMealPlans[index];
        return _buildMealPlanCard(mealPlan);
      },
    );
  }

  /// Build meal plan card
  Widget _buildMealPlanCard(MealPlan mealPlan) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final isActive = mealPlan.isCurrentlyActive;
    final isTemplate = mealPlan.isTemplate;

    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      elevation: isActive ? 4.0 : 1.0,
      color: isActive
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surface,
      child: InkWell(
        onTap: () => _openMealPlan(mealPlan),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      mealPlan.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                  ),

                  // Status badges
                  if (isTemplate)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        'Template',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  if (isActive && !isTemplate) ...[
                    if (isTemplate) const SizedBox(width: 8.0),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        'Active',
                        style: textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],

                  // More actions button
                  PopupMenuButton<String>(
                    onSelected: (action) {
                      switch (action) {
                        case 'edit':
                          _editMealPlan(mealPlan);
                          break;
                        case 'delete':
                          _deleteMealPlan(mealPlan);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete),
                          title: Text('Delete'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 8.0),

              // Date range and stats
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16.0,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    isTemplate ? 'Template' : mealPlan.dateRange,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Icon(
                    Icons.restaurant,
                    size: 16.0,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '${mealPlan.mealSlots.length} slots',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Icon(
                    Icons.assignment,
                    size: 16.0,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4.0),
                  Text(
                    '${mealPlan.assignments.length} recipes',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),

              if (isTemplate &&
                  mealPlan.templateDescription?.isNotEmpty == true) ...[
                const SizedBox(height: 8.0),
                Text(
                  mealPlan.templateDescription!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                    fontStyle: FontStyle.italic,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
