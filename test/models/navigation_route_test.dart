import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomnom/models/navigation_route.dart';

void main() {
  group('NavigationRoute', () {
    const testScreen = Placeholder();

    test('should create NavigationRoute with required properties', () {
      const route = NavigationRoute(
        id: 'test',
        title: 'Test Route',
        icon: Icons.home,
        screen: testScreen,
      );

      expect(route.id, equals('test'));
      expect(route.title, equals('Test Route'));
      expect(route.icon, equals(Icons.home));
      expect(route.screen, equals(testScreen));
      expect(route.isPrimary, isTrue); // default value
    });

    test('should create NavigationRoute with isPrimary set to false', () {
      const route = NavigationRoute(
        id: 'test',
        title: 'Test Route',
        icon: Icons.home,
        screen: testScreen,
        isPrimary: false,
      );

      expect(route.isPrimary, isFalse);
    });

    test('should implement equality correctly', () {
      const route1 = NavigationRoute(
        id: 'test',
        title: 'Test Route',
        icon: Icons.home,
        screen: testScreen,
      );

      const route2 = NavigationRoute(
        id: 'test',
        title: 'Test Route',
        icon: Icons.home,
        screen: testScreen,
      );

      const route3 = NavigationRoute(
        id: 'different',
        title: 'Test Route',
        icon: Icons.home,
        screen: testScreen,
      );

      expect(route1, equals(route2));
      expect(route1, isNot(equals(route3)));
    });

    test('should implement hashCode correctly', () {
      const route1 = NavigationRoute(
        id: 'test',
        title: 'Test Route',
        icon: Icons.home,
        screen: testScreen,
      );

      const route2 = NavigationRoute(
        id: 'test',
        title: 'Test Route',
        icon: Icons.home,
        screen: testScreen,
      );

      expect(route1.hashCode, equals(route2.hashCode));
    });

    test('should implement toString correctly', () {
      const route = NavigationRoute(
        id: 'test',
        title: 'Test Route',
        icon: Icons.home,
        screen: testScreen,
        isPrimary: false,
      );

      final result = route.toString();
      expect(result, contains('NavigationRoute'));
      expect(result, contains('test'));
      expect(result, contains('Test Route'));
      expect(result, contains('false'));
    });
  });
}
