import 'package:flutter/material.dart';

/// A widget for inputting and managing tags with autocomplete functionality
class TagInputWidget extends StatefulWidget {
  final List<String> initialTags;
  final List<String> suggestions;
  final Function(List<String>) onTagsChanged;
  final String? hintText;
  final int? maxTags;
  final int? maxTagLength;
  final bool allowDuplicates;
  final bool caseSensitive;
  final TextStyle? tagTextStyle;
  final TextStyle? inputTextStyle;
  final Color? tagBackgroundColor;
  final Color? tagTextColor;
  final Color? tagBorderColor;
  final EdgeInsetsGeometry? tagPadding;
  final EdgeInsetsGeometry? tagMargin;
  final double? tagBorderRadius;
  final IconData? deleteIcon;
  final Color? deleteIconColor;
  final String? Function(String)? tagValidator;
  final bool enabled;

  const TagInputWidget({
    super.key,
    this.initialTags = const [],
    this.suggestions = const [],
    required this.onTagsChanged,
    this.hintText = 'Add tags...',
    this.maxTags,
    this.maxTagLength = 20,
    this.allowDuplicates = false,
    this.caseSensitive = false,
    this.tagTextStyle,
    this.inputTextStyle,
    this.tagBackgroundColor,
    this.tagTextColor,
    this.tagBorderColor,
    this.tagPadding,
    this.tagMargin,
    this.tagBorderRadius,
    this.deleteIcon,
    this.deleteIconColor,
    this.tagValidator,
    this.enabled = true,
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  late List<String> _tags;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  List<String> _filteredSuggestions = [];
  bool _showSuggestions = false;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _tags = List.from(widget.initialTags);
    _textController = TextEditingController();
    _focusNode = FocusNode();

    _textController.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);

    // Notify about initial tags if any
    if (_tags.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.onTagsChanged(_tags);
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    _textController.dispose();
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  @override
  void didUpdateWidget(TagInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update tags if initialTags changed
    if (oldWidget.initialTags != widget.initialTags) {
      setState(() {
        _tags = List.from(widget.initialTags);
      });
      // Notify about the change
      widget.onTagsChanged(_tags);
    }

    // Update suggestions if they changed
    if (oldWidget.suggestions != widget.suggestions) {
      _updateSuggestions();
    }
  }

  void _onTextChanged() {
    final text = _textController.text;

    // Handle comma or space separation
    if (text.contains(',') || text.contains(' ')) {
      final parts = text.split(RegExp(r'[,\s]+'));
      for (final part in parts) {
        final trimmed = part.trim();
        if (trimmed.isNotEmpty) {
          _addTag(trimmed);
        }
      }
      _textController.clear();
      return;
    }

    _updateSuggestions();
  }

  void _onFocusChanged() {
    if (_focusNode.hasFocus) {
      _updateSuggestions();
    } else {
      _hideSuggestions();
    }
  }

  void _updateSuggestions() {
    final query = _textController.text.toLowerCase().trim();

    if (query.isEmpty) {
      setState(() {
        _filteredSuggestions = widget.suggestions.take(10).toList();
        _showSuggestions = widget.suggestions.isNotEmpty && _focusNode.hasFocus;
      });
    } else {
      final filtered = widget.suggestions
          .where((suggestion) {
            final suggestionLower = suggestion.toLowerCase();
            return suggestionLower.contains(query) &&
                !_tags.any(
                  (tag) => widget.caseSensitive
                      ? tag == suggestion
                      : tag.toLowerCase() == suggestionLower,
                );
          })
          .take(10)
          .toList();

      // Sort by relevance (starts with query first)
      filtered.sort((a, b) {
        final aLower = a.toLowerCase();
        final bLower = b.toLowerCase();
        final aStarts = aLower.startsWith(query);
        final bStarts = bLower.startsWith(query);

        if (aStarts && !bStarts) return -1;
        if (bStarts && !aStarts) return 1;
        return aLower.compareTo(bLower);
      });

      setState(() {
        _filteredSuggestions = filtered;
        _showSuggestions = filtered.isNotEmpty && _focusNode.hasFocus;
      });
    }

    if (_showSuggestions) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _hideSuggestions() {
    setState(() {
      _showSuggestions = false;
    });
    _removeOverlay();
  }

  void _showOverlay() {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0, 56), // Adjust based on input field height
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 300, // Fixed width for overlay
              constraints: const BoxConstraints(maxHeight: 200),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                ),
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _filteredSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _filteredSuggestions[index];
                  return ListTile(
                    dense: true,
                    title: Text(
                      suggestion,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    onTap: () {
                      _addTag(suggestion);
                      _textController.clear();
                      _hideSuggestions();
                      _focusNode.requestFocus();
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _addTag(String tag) {
    final trimmed = tag.trim();

    if (trimmed.isEmpty) return;

    // Validate tag length
    if (widget.maxTagLength != null && trimmed.length > widget.maxTagLength!) {
      _showError('Tag cannot exceed ${widget.maxTagLength} characters');
      return;
    }

    // Check max tags limit
    if (widget.maxTags != null && _tags.length >= widget.maxTags!) {
      _showError('Maximum ${widget.maxTags} tags allowed');
      return;
    }

    // Check for duplicates
    if (!widget.allowDuplicates) {
      final exists = _tags.any(
        (existingTag) => widget.caseSensitive
            ? existingTag == trimmed
            : existingTag.toLowerCase() == trimmed.toLowerCase(),
      );

      if (exists) {
        _showError('Tag already exists');
        return;
      }
    }

    // Custom validation
    if (widget.tagValidator != null) {
      final error = widget.tagValidator!(trimmed);
      if (error != null) {
        _showError(error);
        return;
      }
    }

    setState(() {
      _tags.add(trimmed);
    });

    widget.onTagsChanged(_tags);
    _updateSuggestions();
  }

  void _removeTag(int index) {
    if (index >= 0 && index < _tags.length) {
      setState(() {
        _tags.removeAt(index);
      });
      widget.onTagsChanged(_tags);
      _updateSuggestions();
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _onSubmitted(String value) {
    if (value.trim().isNotEmpty) {
      _addTag(value.trim());
      _textController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return CompositedTransformTarget(
      link: _layerLink,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tags display
          if (_tags.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color:
                      widget.tagBorderColor ??
                      theme.colorScheme.outline.withValues(alpha: 0.2),
                ),
                borderRadius: BorderRadius.circular(
                  widget.tagBorderRadius ?? 8,
                ),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.asMap().entries.map((entry) {
                  final index = entry.key;
                  final tag = entry.value;

                  return _TagChip(
                    tag: tag,
                    onDeleted: widget.enabled ? () => _removeTag(index) : null,
                    textStyle: widget.tagTextStyle,
                    backgroundColor: widget.tagBackgroundColor,
                    textColor: widget.tagTextColor,
                    borderColor: widget.tagBorderColor,
                    padding: widget.tagPadding,
                    margin: widget.tagMargin,
                    borderRadius: widget.tagBorderRadius,
                    deleteIcon: widget.deleteIcon,
                    deleteIconColor: widget.deleteIconColor,
                  );
                }).toList(),
              ),
            ),

          const SizedBox(height: 8),

          // Input field
          TextField(
            controller: _textController,
            focusNode: _focusNode,
            enabled: widget.enabled,
            style: widget.inputTextStyle ?? theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: widget.hintText,
              border: const OutlineInputBorder(),
              suffixIcon: _textController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _onSubmitted(_textController.text),
                    )
                  : null,
            ),
            onSubmitted: _onSubmitted,
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final VoidCallback? onDeleted;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? borderColor;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final IconData? deleteIcon;
  final Color? deleteIconColor;

  const _TagChip({
    required this.tag,
    this.onDeleted,
    this.textStyle,
    this.backgroundColor,
    this.textColor,
    this.borderColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.deleteIcon,
    this.deleteIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: margin ?? const EdgeInsets.only(right: 4, bottom: 4),
      child: Chip(
        label: Text(
          tag,
          style:
              textStyle ??
              TextStyle(
                color: textColor ?? theme.colorScheme.onSecondaryContainer,
                fontSize: 14,
              ),
        ),
        backgroundColor:
            backgroundColor ?? theme.colorScheme.secondaryContainer,
        side: borderColor != null ? BorderSide(color: borderColor!) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 16),
        ),
        padding:
            padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        deleteIcon: Icon(
          deleteIcon ?? Icons.close,
          size: 18,
          color: deleteIconColor ?? theme.colorScheme.onSecondaryContainer,
        ),
        onDeleted: onDeleted,
      ),
    );
  }
}
