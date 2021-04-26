import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand_terminal/console.dart';

typedef KeyCallback = bool Function(Key);

class InputLoop {
  final Console console;
  final List<KeyCallback> _additionalListeners = [];

  InputLoop(this.console);

  /// Listens to the callback. If the callback returns [false], it stops
  /// listening. [breakOn] stops when one of the given [ControlCharacter]s are
  /// found.
  void listen(KeyCallback keyCallback, {List<ControlCharacter> breakOn = const []}) {
    Key key;
    while ((key = console.readKey()) != null) {
      for (var listener in _additionalListeners) {
        if (!listener(key)) {
          break;
        }
      }

      if (breakOn.contains(key.controlChar)) {
        break;
      }

      if (!keyCallback(key)) {
        break;
      }
    }
  }

  /// Adds an additional listener to be called whenever a key is typed and it
  /// is actively listening. Used by navigation.
  void addAdditionalListener(KeyCallback callback) =>
      _additionalListeners.add(callback);
}
