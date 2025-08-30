import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/navigation_routes.dart';
import '../models/navigation_route.dart';
import '../widgets/main_scaffold.dart';

/// Exception thrown when navigation fails
class NavigationException implements Exception {
  final String message;
  final String? routeId;
  final Exception? originalException;

  const NavigationException(
    this.message, {
    this.routeId,
    this.originalException,
  });

  @override
  String toString() => 'NavigationException: $message';
}

/// Service for handling navigation between screens with error handling
class NavigationService {
  /// Navigate to a specific route with error handling
  static Future<bool> navigateToRoute(
    BuildContext context,
    String routeId,
  ) async {
    try {
      if (!context.mounted) {
        throw const NavigationException('Context is no longer mounted');
      }

      final route = NavigationRoutes.findRouteById(routeId);
      if (route == null) {
        throw NavigationException('Route not found', routeId: routeId);
      }

      return await _navigateToScreen(context, route);
    } catch (e) {
      return await _handleNavigationError(context, e, routeId: routeId);
    }
  }

  /// Navigate to a specific navigation route with error handling
  static Future<bool> navigateToScreen(
    BuildContext context,
    NavigationRoute route,
  ) async {
    try {
      if (!context.mounted) {
        throw const NavigationException('Context is no longer mounted');
      }

      return await _navigateToScreen(context, route);
    } catch (e) {
      return await _handleNavigationError(context, e, routeId: route.id);
    }
  }

  /// Navigate to the default route (recipes) with error handling
  static Future<bool> navigateToDefaultRoute(BuildContext context) async {
    try {
      if (!context.mounted) {
        throw const NavigationException('Context is no longer mounted');
      }

      return await _navigateToDefaultRoute(context);
    } catch (e) {
      // If even default navigation fails, show critical error
      _showCriticalError(context, e);
      return false;
    }
  }

  /// Get the current route from the current context
  static String getCurrentRoute(BuildContext context) {
    // Try to find MainScaffold in the widget tree
    final mainScaffold = context.findAncestorWidgetOfExactType<MainScaffold>();
    return mainScaffold?.currentRoute ?? NavigationRoutes.defaultRoute;
  }

  /// Check if a route exists
  static bool routeExists(String routeId) {
    return NavigationRoutes.findRouteById(routeId) != null;
  }

  /// Get all available routes
  static List<NavigationRoute> getAllRoutes() {
    return NavigationRoutes.allRoutes;
  }

  /// Get primary navigation routes
  static List<NavigationRoute> getPrimaryRoutes() {
    return NavigationRoutes.primaryRoutes;
  }

  /// Get secondary navigation routes
  static List<NavigationRoute> getSecondaryRoutes() {
    return NavigationRoutes.secondaryRoutes;
  }

  /// Safely close drawer if open
  static void safeCloseDrawer(BuildContext context) {
    try {
      if (context.mounted && Scaffold.of(context).isDrawerOpen) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      // Ignore drawer close errors - not critical
      debugPrint('Warning: Failed to close drawer: $e');
    }
  }

  // Private helper methods

  static Future<bool> _navigateToScreen(
    BuildContext context,
    NavigationRoute route,
  ) async {
    try {
      if (!context.mounted) {
        throw const NavigationException('Context is no longer mounted');
      }

      // Validate route has required properties
      // Note: route.screen is non-nullable in NavigationRoute model

      // Attempt navigation
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MainScaffold(
            currentScreen: route.screen,
            title: route.title,
            currentRoute: route.id,
          ),
        ),
      );

      return true;
    } catch (e) {
      throw NavigationException(
        'Failed to navigate to screen',
        routeId: route.id,
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  static Future<bool> _navigateToDefaultRoute(BuildContext context) async {
    try {
      final defaultRoute = NavigationRoutes.defaultNavigationRoute;
      return await _navigateToScreen(context, defaultRoute);
    } catch (e) {
      throw NavigationException(
        'Failed to navigate to default route',
        originalException: e is Exception ? e : Exception(e.toString()),
      );
    }
  }

  static Future<bool> _handleNavigationError(
    BuildContext context,
    dynamic error, {
    String? routeId,
  }) async {
    debugPrint('Navigation error: $error');

    if (!context.mounted) {
      return false;
    }

    // Try to recover by navigating to default route
    try {
      final success = await _navigateToDefaultRoute(context);
      if (success && context.mounted) {
        _showRecoveryMessage(context, error, routeId: routeId);
        return true;
      }
    } catch (recoveryError) {
      debugPrint('Recovery navigation failed: $recoveryError');
    }

    // If recovery fails, show critical error
    if (context.mounted) {
      _showCriticalError(context, error);
    }
    return false;
  }

  static void _showRecoveryMessage(
    BuildContext context,
    dynamic error, {
    String? routeId,
  }) {
    if (!context.mounted) return;

    final message = routeId != null
        ? 'Could not open $routeId. Redirected to home screen.'
        : 'Navigation failed. Redirected to home screen.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Retry',
          onPressed: () {
            if (routeId != null && context.mounted) {
              navigateToRoute(context, routeId);
            }
          },
        ),
      ),
    );
  }

  static void _showCriticalError(BuildContext context, dynamic error) {
    if (!context.mounted) return;

    // Provide haptic feedback for critical errors
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.error_outline, color: Colors.red, size: 48),
        title: const Text('Navigation Error'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'The app encountered a navigation error and cannot continue normally.',
            ),
            const SizedBox(height: 16),
            Text(
              'Error details: ${error.toString()}',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              final currentContext = context;
              if (currentContext.mounted) {
                Navigator.of(currentContext).pop();
                // Try one more time to navigate to default
                _navigateToDefaultRoute(currentContext);
              }
            },
            child: const Text('Try Again'),
          ),
          FilledButton(
            onPressed: () {
              // Close the app as last resort
              SystemNavigator.pop();
            },
            child: const Text('Close App'),
          ),
        ],
      ),
    );
  }
}
