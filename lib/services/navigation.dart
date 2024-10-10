import 'package:flutter/material.dart';

/// NavigationService provides a centralized way to handle navigation
/// throughout the application without requiring a BuildContext.
class NavigationService {
  /// GlobalKey used to access the NavigatorState
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigates to a new route
  ///
  /// [routeName] is the name of the route to navigate to
  /// Returns a Future that completes after the navigator finishes pushing the route
  Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  /// Replaces the current route with a new one
  ///
  /// [routeName] is the name of the route to navigate to
  /// Returns a Future that completes after the navigator finishes pushing the route
  Future<dynamic> replaceTo(String routeName) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName);
  }

  /// Closes the current route and returns to the previous one
  void goBack() {
    return navigatorKey.currentState!.pop();
  }
}

/// A global instance of NavigationService for easy access throughout the app
final navigationService = NavigationService();