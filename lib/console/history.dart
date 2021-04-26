import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/input_loop.dart';

typedef NavCreator = Navigation Function();

class Navigator {
  final _history = <_HistoryEntry>[];
  final _routes = <String, NavCreator>{};

  final Context context;

  Navigator(this.context, InputLoop inputLoop) {
    inputLoop.addAdditionalListener((key) {
      if (key.controlChar == ControlCharacter.end && canGoBack()) {
        goBack();
        return false;
      }

      return true;
    });
  }

  /// Adds an available named route, to be directed to via [routeToName(String)].
  void addRoute(String name, NavCreator navCreator) {
    _routes[name] = navCreator;
  }

  /// Routes to a named route set by [addRoute(String, Navigation)].
  /// Before the route is shown, the cursor position is reset to
  /// [Context#startContent]
  FutureOr<dynamic> routeToName(String name, [Map<String, dynamic> payload]) =>
      routeTo(_routes[name](), payload);

  /// Routes to an arbitrary [Navigation].
  /// Before the route is shown, the cursor position is reset to
  /// [Context#startContent]
  FutureOr<dynamic> routeTo(Navigation navigation, [Map<String, dynamic> payload]) {
    _history.add(_HistoryEntry(navigation, payload));
    navigation.initialNav(payload);
    context.console.console.cursorPosition = context.startContent;
    var result = navigation.display(payload);
    if (result is Future) {
      result.whenComplete(() => _history.removeLast());
    } else {
      _history.removeLast();
    }
    return result;
  }

  /// Checks if [#goBack()] should do anything.
  bool canGoBack() => _history.length > 1;

  /// Goes back in history, to the previous navigation AND payload.
  void goBack() {
    if (canGoBack()) {
      context.console.console.cursorPosition = context.startContent;
      _history
          .removeLast()
          .navigation
          .destroy();
      context.console.console.cursorPosition = context.startContent;

      _history.last.redisplay();
    }
  }
}

class _HistoryEntry {
  final Navigation navigation;
  final Map<String, dynamic> payload;

  _HistoryEntry(this.navigation, this.payload);

  void redisplay() => navigation.display(payload);
}

abstract class Navigation {
  final Navigator navigator;
  final Context context;

  Navigation(this.navigator, this.context);

  /// Invoked only if directly navigated to the page, not going back in history
  /// leading to here. This is primarily used for breadcrumbs.
  void initialNav(Map<String, dynamic> payload) {}

  /// Displays the current page
  FutureOr<dynamic> display(Map<String, dynamic> payload);

  /// Clears the screen and resets the cursor. Only called if [#display()] has
  /// not been completed.
  void destroy();
}
