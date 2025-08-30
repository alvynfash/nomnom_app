import 'package:flutter/material.dart';
import '../models/meal_plan.dart';
import '../models/meal_slot.dart';

/// Dialog for creating or editing meal plans
class MealPlanFormDialog extends StatefulWidget {
  /// Existing meal plan to edit (null for creating new)
  final MealPlan? existingMealPlan;

  /// Available meal slots for the family
  final List<MealSlot> availableMealSlots;

  /// Callback when meal plan is saved
  final Function(MealPlan) onSave;

  /// Family ID for the meal plan
  final String familyId;

  /// User ID for creation tracking
  final String userId;

  const MealPlanFormDialog({
    super.key,
    this.existingMealPlan,
    required this.availableMealSlots,
    required this.onSave,
    required this.familyId,
    required this.userId,
  });

  @override
  State<MealPlanFormDialog> createState() => _MealPlanFormDialogState();
}

class _MealPlanFormDialogState extends State<MealPlanFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  DateTime _selectedStartDate = DateTime.now();
  List<String> _selectedMealSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Initialize form with existing meal plan data or defaults
  void _initializeForm() {
    if (widget.existingMealPlan != null) {
      _nameController.text = widget.existingMealPlan!.name;
      _selectedStartDate = widget.existingMealPlan!.startDate;
      _selectedMealSlots = List.from(widget.existingMealPlan!.mealSlots);
    } else {
      _nameController.text = '';
      _selectedStartDate = _getStartOfCurrentWeek();
      _selectedMealSlots = widget.availableMealSlots
          .where((slot) => slot.isDefault)
          .map((slot) => slot.id)
          .toList();
    }
  }

  /// Get the start of the current week (Monday)
  DateTime _getStartOfCurrentWeek() {
    final now = DateTime.now();
    final daysFromMonday = now.weekday - 1;
    return DateTime(now.year, now.month, now.day - daysFromMonday);
  }

  /// Handle form submission
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMealSlots.isEmpty) {
      _showErrorSnackBar('Please select at least one meal slot');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final mealPlan =
          widget.existingMealPlan?.copyWith(
            name: _nameController.text.trim(),
            startDate: _selectedStartDate,
            mealSlots: _selectedMealSlots,
            updatedAt: DateTime.now(),
          ) ??
          MealPlan.create(
            name: _nameController.text.trim(),
            familyId: widget.familyId,
            startDate: _selectedStartDate,
            mealSlots: _selectedMealSlots,
            createdBy: widget.userId,
          );

      widget.onSave(mealPlan);

      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      _showErrorSnackBar('Failed to save meal plan: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Show date picker for start date selection
  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: 'Select meal plan start date',
      fieldLabelText: 'Start date',
    );

    if (picked != null) {
      setState(() {
        // Ensure the selected date is a Monday (start of week)
        final daysFromMonday = picked.weekday - 1;
        _selectedStartDate = DateTime(
          picked.year,
          picked.month,
          picked.day - daysFromMonday,
        );
      });
    }
  }

  /// Toggle meal slot selection
  void _toggleMealSlot(String slotId) {
    setState(() {
      if (_selectedMealSlots.contains(slotId)) {
        _selectedMealSlots.remove(slotId);
      } else {
        _selectedMealSlots.add(slotId);
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(context),

              const SizedBox(height: 24.0),

              // Meal plan name field
              _buildNameField(context),

              const SizedBox(height: 20.0),

              // Start date selection
              _buildStartDateField(context),

              const SizedBox(height: 20.0),

              // Meal slots selection
              _buildMealSlotsSection(context),

              const SizedBox(height: 24.0),

              // Action buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  /// Build dialog header
  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            widget.existingMealPlan != null
                ? 'Edit Meal Plan'
                : 'Create Meal Plan',
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ],
    );
  }

  /// Build meal plan name field
  Widget _buildNameField(BuildContext context) {
    return TextFormField(
      controller: _nameController,
      decoration: const InputDecoration(
        labelText: 'Meal Plan Name',
        hintText: 'Enter a name for your meal plan',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.restaurant_menu),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a meal plan name';
        }
        if (value.trim().length > 50) {
          return 'Name must be 50 characters or less';
        }
        return null;
      },
      textInputAction: TextInputAction.next,
    );
  }

  /// Build start date field
  Widget _buildStartDateField(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return InkWell(
      onTap: _selectStartDate,
      borderRadius: BorderRadius.circular(4.0),
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Start Date (Week Beginning)',
          border: OutlineInputBorder(),
          prefixIcon: Icon(Icons.calendar_today),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatStartDate(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  /// Format start date for display
  String _formatStartDate() {
    final endDate = _selectedStartDate.add(const Duration(days: 27));
    return '${_selectedStartDate.month}/${_selectedStartDate.day}/${_selectedStartDate.year} - ${endDate.month}/${endDate.day}/${endDate.year}';
  }

  /// Build meal slots selection section
  Widget _buildMealSlotsSection(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Meal Slots',
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8.0),
        Text(
          'Select which meal slots to include in your meal plan',
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 12.0),

        // Meal slot chips
        Wrap(
          spacing: 8.0,
          runSpacing: 8.0,
          children: widget.availableMealSlots.map((slot) {
            final isSelected = _selectedMealSlots.contains(slot.id);

            return FilterChip(
              label: Text(slot.name),
              selected: isSelected,
              onSelected: (_) => _toggleMealSlot(slot.id),
              backgroundColor: colorScheme.surfaceContainerLow,
              selectedColor: colorScheme.primaryContainer,
              checkmarkColor: colorScheme.onPrimaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),

        if (_selectedMealSlots.isEmpty) ...[
          const SizedBox(height: 8.0),
          Text(
            'Please select at least one meal slot',
            style: textTheme.bodySmall?.copyWith(color: colorScheme.error),
          ),
        ],
      ],
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Cancel button
        Expanded(
          child: OutlinedButton(
            onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),

        const SizedBox(width: 12.0),

        // Save button
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleSubmit,
            child: _isLoading
                ? const SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  )
                : Text(widget.existingMealPlan != null ? 'Update' : 'Create'),
          ),
        ),
      ],
    );
  }
}

/// Show meal plan form dialog
Future<MealPlan?> showMealPlanFormDialog({
  required BuildContext context,
  MealPlan? existingMealPlan,
  required List<MealSlot> availableMealSlots,
  required String familyId,
  required String userId,
}) async {
  MealPlan? result;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (context) => MealPlanFormDialog(
      existingMealPlan: existingMealPlan,
      availableMealSlots: availableMealSlots,
      familyId: familyId,
      userId: userId,
      onSave: (mealPlan) {
        result = mealPlan;
      },
    ),
  );

  return result;
}
