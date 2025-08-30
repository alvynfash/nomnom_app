import 'dart:async';
import 'package:flutter/material.dart';

/// A widget that provides search functionality with tag filtering capabilities
class SearchBarWidget extends StatefulWidget {
  final String? initialQuery;
  final List<String> initialTagFilters;
  final List<String> availableTags;
  final Function(String) onSearchChanged;
  final Function(List<String>) onTagFiltersChanged;
  final String? hintText;
  final bool enabled;
  final bool showTagFilters;
  final int maxTagFilters;
  final TextStyle? textStyle;
  final InputDecoration? decoration;
  final Duration debounceDelay;

  const SearchBarWidget({
    super.key,
    this.initialQuery,
    this.initialTagFilters = const [],
    this.availableTags = const [],
    required this.onSearchChanged,
    required this.onTagFiltersChanged,
    this.hintText = 'Search recipes...',
    this.enabled = true,
    this.showTagFilters = true,
    this.maxTagFilters = 5,
    this.textStyle,
    this.decoration,
    this.debounceDelay = const Duration(milliseconds: 300),
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _searchController;
  late List<String> _selectedTagFilters;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _selectedTagFilters = List.from(widget.initialTagFilters);

    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(SearchBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Update search text if initialQuery changed
    if (oldWidget.initialQuery != widget.initialQuery) {
      _searchController.text = widget.initialQuery ?? '';
    }

    // Update tag filters if initialTagFilters changed
    if (oldWidget.initialTagFilters != widget.initialTagFilters) {
      setState(() {
        _selectedTagFilters = List.from(widget.initialTagFilters);
      });
    }
  }

  void _onSearchTextChanged() {
    final query = _searchController.text;

    // Cancel previous timer
    _debounceTimer?.cancel();

    // Rebuild to update suffix icon
    setState(() {});

    // Start new timer
    _debounceTimer = Timer(widget.debounceDelay, () {
      widget.onSearchChanged(query);
    });
  }

  void _toggleTagFilter(String tag) {
    setState(() {
      if (_selectedTagFilters.contains(tag)) {
        _selectedTagFilters.remove(tag);
      } else {
        if (_selectedTagFilters.length < widget.maxTagFilters) {
          _selectedTagFilters.add(tag);
        }
      }
    });

    widget.onTagFiltersChanged(_selectedTagFilters);
  }

  void _clearTagFilters() {
    setState(() {
      _selectedTagFilters.clear();
    });
    widget.onTagFiltersChanged(_selectedTagFilters);
  }

  void _clearSearch() {
    _searchController.clear();
    widget.onSearchChanged('');
  }

  Widget? _buildSuffixIcon() {
    final List<Widget> actions = [];

    // Clear search button
    if (_searchController.text.isNotEmpty) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: widget.enabled ? _clearSearch : null,
          tooltip: 'Clear search',
        ),
      );
    }

    // Tag filter button
    if (widget.showTagFilters && widget.availableTags.isNotEmpty) {
      actions.add(
        IconButton(
          icon: Badge(
            isLabelVisible: _selectedTagFilters.isNotEmpty,
            label: Text(_selectedTagFilters.length.toString()),
            child: const Icon(Icons.filter_list),
          ),
          onPressed: widget.enabled ? _showTagFilterBottomSheet : null,
          tooltip: 'Filter by tags',
        ),
      );
    }

    if (actions.isEmpty) return null;
    if (actions.length == 1) return actions.first;

    return Row(mainAxisSize: MainAxisSize.min, children: actions);
  }

  void _showTagFilterBottomSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.7,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Filter by Tags',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Row(
                        children: [
                          if (_selectedTagFilters.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setModalState(() {
                                  _clearTagFilters();
                                });
                                setState(() {});
                              },
                              child: const Text('Clear All'),
                            ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Selected tags count
                  if (_selectedTagFilters.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        '${_selectedTagFilters.length} tag${_selectedTagFilters.length == 1 ? '' : 's'} selected',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),

                  // Available tags
                  Flexible(
                    child: widget.availableTags.isEmpty
                        ? Center(
                            child: Text(
                              'No tags available',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: widget.availableTags.length,
                            itemBuilder: (context, index) {
                              final tag = widget.availableTags[index];
                              final isSelected = _selectedTagFilters.contains(
                                tag,
                              );

                              return CheckboxListTile(
                                title: Text(tag),
                                value: isSelected,
                                onChanged: widget.enabled
                                    ? (bool? value) {
                                        setModalState(() {
                                          _toggleTagFilter(tag);
                                        });
                                        setState(() {});
                                      }
                                    : null,
                                dense: true,
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search input field
        TextField(
          controller: _searchController,
          enabled: widget.enabled,
          style: widget.textStyle,
          decoration:
              widget.decoration ??
              InputDecoration(
                hintText: widget.hintText,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _buildSuffixIcon(),
                border: const OutlineInputBorder(),
              ),
        ),

        // Selected tag filters display
        if (_selectedTagFilters.isNotEmpty && widget.showTagFilters)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filtered by:',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedTagFilters.map((tag) {
                    return FilterChip(
                      label: Text(tag),
                      selected: true,
                      onSelected: widget.enabled
                          ? (bool selected) {
                              if (!selected) {
                                _toggleTagFilter(tag);
                              }
                            }
                          : null,
                      onDeleted: widget.enabled
                          ? () => _toggleTagFilter(tag)
                          : null,
                      deleteIcon: const Icon(Icons.close, size: 16),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
