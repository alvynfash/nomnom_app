import 'package:flutter/material.dart';

/// Custom page route that provides smooth fade in/out transitions
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget child;
  final Duration duration;
  final Duration reverseDuration;

  FadePageRoute({
    required this.child,
    this.duration = const Duration(milliseconds: 300),
    this.reverseDuration = const Duration(milliseconds: 250),
    super.settings,
  }) : super(
         pageBuilder: (context, animation, secondaryAnimation) => child,
         transitionDuration: duration,
         reverseTransitionDuration: reverseDuration,
         transitionsBuilder: (context, animation, secondaryAnimation, child) {
           // Fade transition for the incoming page
           final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
             CurvedAnimation(parent: animation, curve: Curves.easeInOut),
           );

           // Optional: Add a slight scale effect for more polish
           final scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
             CurvedAnimation(parent: animation, curve: Curves.easeInOut),
           );

           return FadeTransition(
             opacity: fadeAnimation,
             child: ScaleTransition(scale: scaleAnimation, child: child),
           );
         },
       );
}

/// Extension on Navigator for easy fade navigation
extension NavigatorFadeExtension on NavigatorState {
  /// Push a new route with fade transition
  Future<T?> pushFade<T extends Object?>(Widget page) {
    return push<T>(FadePageRoute<T>(child: page));
  }

  /// Push and replace current route with fade transition
  Future<T?> pushReplacementFade<T extends Object?, TO extends Object?>(
    Widget page, {
    TO? result,
  }) {
    return pushReplacement<T, TO>(
      FadePageRoute<T>(child: page),
      result: result,
    );
  }

  /// Push and remove all previous routes with fade transition
  Future<T?> pushAndRemoveUntilFade<T extends Object?>(
    Widget page,
    RoutePredicate predicate,
  ) {
    return pushAndRemoveUntil<T>(FadePageRoute<T>(child: page), predicate);
  }
}

/// Static helper methods for fade navigation
class FadeNavigation {
  /// Push a new route with fade transition
  static Future<T?> push<T extends Object?>(BuildContext context, Widget page) {
    return Navigator.of(context).push<T>(FadePageRoute<T>(child: page));
  }

  /// Push and replace current route with fade transition
  static Future<T?> pushReplacement<T extends Object?, TO extends Object?>(
    BuildContext context,
    Widget page, {
    TO? result,
  }) {
    return Navigator.of(
      context,
    ).pushReplacement<T, TO>(FadePageRoute<T>(child: page), result: result);
  }

  /// Push and remove all previous routes with fade transition
  static Future<T?> pushAndRemoveUntil<T extends Object?>(
    BuildContext context,
    Widget page,
    RoutePredicate predicate,
  ) {
    return Navigator.of(
      context,
    ).pushAndRemoveUntil<T>(FadePageRoute<T>(child: page), predicate);
  }
}
