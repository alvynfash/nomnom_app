import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/sidebar_state.dart';

void main() {
  group('SidebarState', () {
    test('should create SidebarState with required properties', () {
      const state = SidebarState(currentRoute: 'recipes');

      expect(state.currentRoute, equals('recipes'));
      expect(state.isDrawerOpen, isFalse); // default value
    });

    test('should create SidebarState with isDrawerOpen set to true', () {
      const state = SidebarState(currentRoute: 'recipes', isDrawerOpen: true);

      expect(state.currentRoute, equals('recipes'));
      expect(state.isDrawerOpen, isTrue);
    });

    test('should create copy with updated currentRoute', () {
      const originalState = SidebarState(
        currentRoute: 'recipes',
        isDrawerOpen: true,
      );

      final newState = originalState.copyWith(currentRoute: 'meal_planning');

      expect(newState.currentRoute, equals('meal_planning'));
      expect(newState.isDrawerOpen, isTrue); // preserved
      expect(
        originalState.currentRoute,
        equals('recipes'),
      ); // original unchanged
    });

    test('should create copy with updated isDrawerOpen', () {
      const originalState = SidebarState(
        currentRoute: 'recipes',
        isDrawerOpen: false,
      );

      final newState = originalState.copyWith(isDrawerOpen: true);

      expect(newState.currentRoute, equals('recipes')); // preserved
      expect(newState.isDrawerOpen, isTrue);
      expect(originalState.isDrawerOpen, isFalse); // original unchanged
    });

    test('should create copy with both properties updated', () {
      const originalState = SidebarState(
        currentRoute: 'recipes',
        isDrawerOpen: false,
      );

      final newState = originalState.copyWith(
        currentRoute: 'settings',
        isDrawerOpen: true,
      );

      expect(newState.currentRoute, equals('settings'));
      expect(newState.isDrawerOpen, isTrue);
    });

    test('should create copy with no changes when no parameters provided', () {
      const originalState = SidebarState(
        currentRoute: 'recipes',
        isDrawerOpen: true,
      );

      final newState = originalState.copyWith();

      expect(newState.currentRoute, equals('recipes'));
      expect(newState.isDrawerOpen, isTrue);
      expect(newState, equals(originalState));
    });

    test('should implement equality correctly', () {
      const state1 = SidebarState(currentRoute: 'recipes', isDrawerOpen: true);

      const state2 = SidebarState(currentRoute: 'recipes', isDrawerOpen: true);

      const state3 = SidebarState(
        currentRoute: 'meal_planning',
        isDrawerOpen: true,
      );

      expect(state1, equals(state2));
      expect(state1, isNot(equals(state3)));
    });

    test('should implement hashCode correctly', () {
      const state1 = SidebarState(currentRoute: 'recipes', isDrawerOpen: true);

      const state2 = SidebarState(currentRoute: 'recipes', isDrawerOpen: true);

      expect(state1.hashCode, equals(state2.hashCode));
    });

    test('should implement toString correctly', () {
      const state = SidebarState(currentRoute: 'recipes', isDrawerOpen: true);

      final result = state.toString();
      expect(result, contains('SidebarState'));
      expect(result, contains('recipes'));
      expect(result, contains('true'));
    });
  });
}
