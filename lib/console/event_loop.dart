import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand_terminal/console/loop/event.dart';

typedef KeyCallback = bool Function(Key);

/// Handles synchronous actions in a semi-parallel way by putting synchronous
/// constant loops (e.g. input) into a loop so it may be separated from views.
class EventLoop {
  final Console console;
  final List<Event> _events = [];

  EventLoop(this.console);

  void init() {
    for (var event in _events) {
      event.init();
    }

    Timer.periodic(Duration(milliseconds: 100), (timer) {
      try {
        tick();
      } catch (e, s) {
        timer.cancel();
        print(e);
        print(s);
      }
    });
  }

  /// Invoked 10 times a second
  void tick() {
    for (var event in _events) {
      event.tick();
    }
  }

  void addEvent(Event event) => _events.add(event);
}
