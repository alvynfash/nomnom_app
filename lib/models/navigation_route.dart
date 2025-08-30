import 'package:flutter/material.dart';

/// Represents a navigation route in the app sidebar
class NavigationRoute {
  /// Unique identifier for the route
  final String id;

  /// Display title for the navigation item
  final String title;

  /// Icon to display for the navigation item
  final IconData icon;

  /// The screen widget to navigate to
  final Widget screen;

  /// Whether this is a primary navigation item (shown in main section)
  final bool isPrimary;

  const NavigationRoute({
    required this.id,
    required this.title,
    required this.icon,
    required this.screen,
    this.isPrimary = true,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NavigationRoute &&
        other.id == id &&
        other.title == title &&
        other.icon == icon &&
        other.isPrimary == isPrimary;
  }

  @override
  int get hashCode {
    return id.hashCode ^ title.hashCode ^ icon.hashCode ^ isPrimary.hashCode;
  }

  @override
  String toString() {
    return 'NavigationRoute(id: $id, title: $title, isPrimary: $isPrimary)';
  }
}
