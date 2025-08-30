import 'package:flutter/material.dart';
import '../models/navigation_route.dart';
import '../models/sidebar_state.dart';
import '../services/navigation_service.dart';
import 'app_drawer.dart';

/// Main scaffold wrapper that provides sidebar functionality to all screens
class MainScaffold extends StatefulWidget {
  /// The current screen to display
  final Widget currentScreen;

  /// App bar title for current screen
  final String title;

  /// Optional app bar actions
  final List<Widget>? actions;

  /// Optional floating action button
  final Widget? floatingActionButton;

  /// The current route ID
  final String currentRoute;

  const MainScaffold({
    super.key,
    required this.currentScreen,
    required this.title,
    required this.currentRoute,
    this.actions,
    this.floatingActionButton,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with WidgetsBindingObserver {
  SidebarState _sidebarState = const SidebarState(currentRoute: 'recipes');
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _sidebarState = SidebarState(currentRoute: widget.currentRoute);
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // Handle app lifecycle changes for proper cleanup
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      // Ensure drawer is closed when app goes to background
      NavigationService.safeCloseDrawer(context);
    }
  }

  @override
  void didUpdateWidget(MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDisposed && oldWidget.currentRoute != widget.currentRoute) {
      setState(() {
        _sidebarState = _sidebarState.copyWith(
          currentRoute: widget.currentRoute,
        );
      });
    }
  }

  Future<void> _navigateToScreen(NavigationRoute route) async {
    try {
      // Close the drawer first
      NavigationService.safeCloseDrawer(context);

      // If we're already on this route, don't navigate
      if (route.id == _sidebarState.currentRoute) {
        return;
      }

      // Update the sidebar state optimistically
      if (!_isDisposed) {
        setState(() {
          _sidebarState = _sidebarState.copyWith(currentRoute: route.id);
        });
      }

      // Use NavigationService for consistent navigation handling
      final success = await NavigationService.navigateToScreen(context, route);

      // If navigation failed, revert the state
      if (!success && mounted && !_isDisposed) {
        setState(() {
          _sidebarState = _sidebarState.copyWith(
            currentRoute: widget.currentRoute,
          );
        });
      }
    } catch (e) {
      // Revert state on any error
      if (mounted && !_isDisposed) {
        setState(() {
          _sidebarState = _sidebarState.copyWith(
            currentRoute: widget.currentRoute,
          );
        });
      }

      // Let NavigationService handle the error
      if (mounted) {
        await NavigationService.navigateToScreen(context, route);
      }
    }
  }

  String _getCurrentRoute() {
    return _sidebarState.currentRoute;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        actions: widget.actions,
      ),
      drawer: AppDrawer(
        currentRoute: _getCurrentRoute(),
        onNavigationTap: _navigateToScreen,
      ),
      body: widget.currentScreen,
      floatingActionButton: widget.floatingActionButton,
    );
  }
}
