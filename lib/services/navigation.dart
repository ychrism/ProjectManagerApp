import 'package:flutter/material.dart';

class NavigationService {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  Future<dynamic> navigateTo(String routeName) {
    return navigatorKey.currentState!.pushNamed(routeName);
  }

  Future<dynamic> replaceTo(String routeName) {
    return navigatorKey.currentState!.pushReplacementNamed(routeName);
  }

  void goBack() {
    return navigatorKey.currentState!.pop();
  }
}

final navigationService = NavigationService();