/// Represents the current state of the sidebar navigation
class SidebarState {
  /// The currently active route ID
  final String currentRoute;

  /// Whether the drawer is currently open
  final bool isDrawerOpen;

  const SidebarState({required this.currentRoute, this.isDrawerOpen = false});

  /// Creates a copy of this state with updated values
  SidebarState copyWith({String? currentRoute, bool? isDrawerOpen}) {
    return SidebarState(
      currentRoute: currentRoute ?? this.currentRoute,
      isDrawerOpen: isDrawerOpen ?? this.isDrawerOpen,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SidebarState &&
        other.currentRoute == currentRoute &&
        other.isDrawerOpen == isDrawerOpen;
  }

  @override
  int get hashCode {
    return currentRoute.hashCode ^ isDrawerOpen.hashCode;
  }

  @override
  String toString() {
    return 'SidebarState(currentRoute: $currentRoute, isDrawerOpen: $isDrawerOpen)';
  }
}
