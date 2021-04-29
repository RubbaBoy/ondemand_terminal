import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/event_loop.dart';
import 'package:ondemand_terminal/console/input_loop.dart';
import 'package:ondemand_terminal/console/loop/event.dart';

typedef NavCreator = Navigation Function();

class Navigator extends Event {
  final _history = <_HistoryEntry>[];
  final _routes = <String, NavCreator>{};

  final Context context;

  /// The next nav item to process in [#tick()].
  NavItem nextItem;

  Navigator(this.context, InputLoop inputLoop, EventLoop eventLoop) {
    eventLoop.addEvent(this);
    inputLoop.addAdditionalListener((key) {
      if (key.controlChar == ControlCharacter.end && canGoBack()) {
        return false;
      }

      return true;
    }, () {
      goBack();
    });
  }

  /// Adds an available named route, to be directed to via [routeToName(String)].
  void addRoute(String name, NavCreator navCreator) {
    _routes[name] = navCreator;
  }

  /// Routes to a named route set by [addRoute(String, Navigation)].
  /// Before the route is shown, the cursor position is reset to
  /// [Context#startContent]
  Future<Optional<T>> routeToName<T>(String name,
          [Map<String, dynamic> payload]) =>
      routeTo(_routes[name](), payload);

  /// Routes to an arbitrary [Navigation].
  /// Before the route is shown, the cursor position is reset to
  /// [Context#startContent]
  Future<Optional<T>> routeTo<T>(Navigation navigation,
      [Map<String, dynamic> payload]) {
    var entry =
        _HistoryEntry<T>(navigation, payload, () => _history.removeLast());
    try {
      _history.add(entry);
      return entry._completer.future;
    } finally {
      // We do NOT want this happening before the future!
      nextItem = entry;
    }
  }

  /// Checks if [#goBack()] should do anything.
  bool canGoBack() => _history.length > 1;

  /// Goes back in history, to the previous navigation AND payload.
  void goBack() {
    if (canGoBack()) {
      nextItem = NavItem.GoBack;
    }
  }

  void _goBack() {
    context.console.console.cursorPosition = context.startContent;
    _history.removeLast().destroy();

    context.console.console.cursorPosition = context.startContent;
    _history.last.redisplay();
  }

  @override
  void tick() {
    if (nextItem == null) {
      return;
    }

    if (nextItem.action == NavAction.GoBack) {
      _goBack();
      nextItem = null;
      return;
    }

    context.console.console.cursorPosition = context.startContent;
    var item = nextItem as _HistoryEntry;
    item.display();

    nextItem = null;
  }
}

enum NavAction {
  /// Navigating to a specific page
  NavTo,

  /// Going back in history
  GoBack
}

class NavItem {
  static const GoBack = NavItem(NavAction.GoBack);

  final NavAction action;

  const NavItem(this.action);

  @override
  String toString() => 'NavItem[$action]';
}

class _HistoryEntry<T> extends NavItem {
  final Navigation navigation;
  final Map<String, dynamic> payload;
  final Function onExit;
  Completer<Optional<T>> _completer = Completer<Optional<T>>();

  /// [onExit] is meant for removing it from the history, invoked when the
  /// display method is finished (or it is backed out).
  _HistoryEntry(this.navigation, this.payload, this.onExit)
      : super(NavAction.NavTo);

  Future<dynamic> display() {
    navigation.initialNav(payload);
    redisplay();
    return _completer.future;
  }

  void destroy() {
    navigation.destroy();
    _completer.complete(Optional<T>.error());
    _completer = null;
  }

  void redisplay() {
    Future.value(navigation.display(payload))
        .then((v) {
          _completer.complete(Optional.value(v));
          _completer = null;
        })
        .then((_) => onExit())
        .catchError((e) {
          // print(e);
          // This is yucky but whatever
        }, test: (e) => e is InputBreakException);
  }
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

  ///
  /// var waitedFuture = await nav.routeToName('whatever');
  /// if (waitedFuture.error) return;
  /// var waited = waitedFuture.value;
}

class Optional<T> {
  /// If an error occurred while getting the value for whatever reason.
  final bool error;

  final T value;

  Optional.value(this.value) : error = false;

  const Optional.error()
      : error = true,
        value = null;

  /// If no error present, this transforms the value and returns a new
  /// [Optional].
  Optional<V> transform<V>(V Function(T) transform) =>
      error ? Optional.error() : Optional.value(transform(value));
}

class BackException {}
