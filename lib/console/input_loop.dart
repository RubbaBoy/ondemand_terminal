import 'dart:async';
import 'dart:cli';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/loop/event.dart';

typedef KeyCallback = bool Function(Key);

@deprecated
class InputLoop extends Event {
  final Console console;
  final List<KeyCallback> _additionalListeners = [];

  bool _listeningKeys = false;
  List<ControlCharacter> _breakOn = [];
  KeyCallback _keyCallback;
  Completer _completer;

  InputLoop(this.console);

  /// Listens to the callback. If the callback returns [false], it stops
  /// listening. [breakOn] stops when one of the given [ControlCharacter]s are
  /// found.
  Future<void> listen(KeyCallback keyCallback, {List<ControlCharacter> breakOn = const []}) {
    _breakOn = breakOn;
    _keyCallback = keyCallback;
    _listeningKeys = true;
    return (_completer = Completer()).future;
  }

  /// Adds an additional listener to be called whenever a key is typed and it
  /// is actively listening. Used by navigation.
  void addAdditionalListener(KeyCallback callback) =>
      _additionalListeners.add(callback);

  void _complete() {
    _completer.complete();
    _listeningKeys = false;
  }

  @override
  void tick() {
    if (!_listeningKeys) {
      return;
    }

    var key = console.readKey();
    for (var listener in _additionalListeners) {
      if (!listener(key)) {
        _complete();
        return;
      }
    }

    if (_breakOn.contains(key.controlChar)) {
      _complete();
      return;
    }

    if (!_keyCallback(key)) {
      _complete();
    }
  }
}
