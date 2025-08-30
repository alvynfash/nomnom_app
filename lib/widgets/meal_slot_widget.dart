import 'package:flutter/material.dart';
import '../models/meal_slot.dart';
import '../models/recipe.dart';

/// A reusable widget for displaying individual meal slots in meal plans
class MealSlotWidget extends StatefulWidget {
  /// The date this meal slot is for
  final DateTime date;

  /// The meal slot configuration (name, order, etc.)
  final MealSlot slot;

  /// The recipe assigned to this slot (null if no recipe assigned)
  final Recipe? assignedRecipe;

  /// Callback when the slot is tapped
  final VoidCallback onTap;

  /// Whether this slot can be edited (based on permissions)
  final bool isEditable;

  /// Optional custom height for the slot
  final double? height;

  /// Whether to show a compact view (less padding, smaller text)
  final bool isCompact;

  const MealSlotWidget({
    super.key,
    required this.date,
    required this.slot,
    this.assignedRecipe,
    required this.onTap,
    this.isEditable = true,
    this.height,
    this.isCompact = false,
  });

  @override
  State<MealSlotWidget> createState() => _MealSlotWidgetState();
}

class _MealSlotWidgetState extends State<MealSlotWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.isEditable) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.isEditable) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.isEditable) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTap() {
    if (widget.isEditable) {
      widget.onTap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final hasRecipe = widget.assignedRecipe != null;
    final isToday = _isToday(widget.date);
    final isPast = widget.date.isBefore(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // Determine colors based on state
    Color backgroundColor;
    Color borderColor;
    Color textColor;

    if (!widget.isEditable) {
      backgroundColor = colorScheme.surfaceContainerLow;
      borderColor = colorScheme.outline.withValues(alpha: 0.3);
      textColor = colorScheme.onSurface.withValues(alpha: 0.6);
    } else if (hasRecipe) {
      backgroundColor = colorScheme.primaryContainer;
      borderColor = colorScheme.primary;
      textColor = colorScheme.onPrimaryContainer;
    } else {
      backgroundColor = colorScheme.surface;
      borderColor = colorScheme.outline;
      textColor = colorScheme.onSurface;
    }

    // Adjust colors for today
    if (isToday && widget.isEditable) {
      borderColor = colorScheme.secondary;
      if (!hasRecipe) {
        backgroundColor = colorScheme.secondaryContainer.withValues(alpha: .3);
      }
    }

    // Adjust colors for past dates
    if (isPast) {
      backgroundColor = backgroundColor.withValues(alpha: .7);
      textColor = textColor.withValues(alpha: .7);
    }

    final double slotHeight =
        widget.height ?? (widget.isCompact ? 80.0 : 100.0);
    final double padding = widget.isCompact ? 8.0 : 12.0;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            onTap: _handleTap,
            child: Container(
              height: slotHeight,
              margin: EdgeInsets.symmetric(
                vertical: widget.isCompact ? 2.0 : 4.0,
                horizontal: 2.0,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(
                  color: borderColor,
                  width: isToday ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: widget.isEditable && hasRecipe
                    ? [
                        BoxShadow(
                          color: colorScheme.shadow.withValues(alpha: .1),
                          blurRadius: 4.0,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Meal slot name and edit indicator
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.slot.name,
                            style: widget.isCompact
                                ? textTheme.bodySmall?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  )
                                : textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.isEditable)
                          Icon(
                            hasRecipe ? Icons.edit : Icons.add,
                            size: widget.isCompact ? 14.0 : 16.0,
                            color: textColor.withValues(alpha: .7),
                          ),
                      ],
                    ),

                    const SizedBox(height: 4.0),

                    // Recipe information or empty state
                    Expanded(
                      child: hasRecipe
                          ? _buildRecipeInfo(
                              context,
                              widget.assignedRecipe!,
                              textColor,
                            )
                          : _buildEmptyState(context, textColor),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecipeInfo(
    BuildContext context,
    Recipe recipe,
    Color textColor,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recipe title
        Expanded(
          child: Text(
            recipe.title,
            style: widget.isCompact
                ? textTheme.bodySmall?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  )
                : textTheme.bodyMedium?.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w500,
                  ),
            maxLines: widget.isCompact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        const SizedBox(height: 2.0),

        // Recipe details (prep time and servings)
        Row(
          children: [
            if (recipe.totalTime > 0) ...[
              Icon(
                Icons.access_time,
                size: widget.isCompact ? 10.0 : 12.0,
                color: textColor.withValues(alpha: .7),
              ),
              const SizedBox(width: 2.0),
              Text(
                recipe.formattedTime,
                style: widget.isCompact
                    ? textTheme.bodySmall?.copyWith(
                        color: textColor.withValues(alpha: .7),
                        fontSize: 10.0,
                      )
                    : textTheme.bodySmall?.copyWith(
                        color: textColor.withValues(alpha: .7),
                      ),
              ),
              const SizedBox(width: 8.0),
            ],

            Icon(
              Icons.people,
              size: widget.isCompact ? 10.0 : 12.0,
              color: textColor.withValues(alpha: .7),
            ),
            const SizedBox(width: 2.0),
            Text(
              '${recipe.servings}',
              style: widget.isCompact
                  ? textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: .7),
                      fontSize: 10.0,
                    )
                  : textTheme.bodySmall?.copyWith(
                      color: textColor.withValues(alpha: .7),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, Color textColor) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_circle_outline,
            size: widget.isCompact ? 16.0 : 20.0,
            color: textColor.withValues(alpha: .5),
          ),
          const SizedBox(height: 2.0),
          Text(
            widget.isEditable ? 'Add recipe' : 'No recipe',
            style: widget.isCompact
                ? textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: .5),
                    fontSize: 10.0,
                  )
                : textTheme.bodySmall?.copyWith(
                    color: textColor.withValues(alpha: .5),
                  ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
