import 'dart:async';
import 'dart:cli';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/loop/event.dart';

typedef KeyCallback = bool Function(Key);

@deprecated
class InputLoop extends Event {
  final Console console;
  final _additionalListeners = <KeyCallback, Function>{};

  bool _listeningKeys = false;
  List<ControlCharacter> _breakOn = [];
  KeyCallback _keyCallback;
  Completer<bool> _completer;

  InputLoop(this.console);

  /// Listens to the callback. If the callback returns [false], it stops
  /// listening. [breakOn] stops when one of the given [ControlCharacter]s are
  /// found.
  Future<void> listen(KeyCallback keyCallback, {List<ControlCharacter> breakOn = const []}) {
    _breakOn = breakOn;
    _keyCallback = keyCallback;
    _listeningKeys = true;
    _completer = Completer<bool>.sync();
    var c = Completer();

    _completer.future.then((value) {
      if (value) {
        c.completeError(InputBreakException());
      } else {
        c.complete();
      }
    });

    return c.future;
  }

  /// Adds an additional listener to be called whenever a key is typed and it
  /// is actively listening. Used by navigation.
  void addAdditionalListener(KeyCallback callback, [Function after]) =>
      _additionalListeners[callback] = after;

  void _complete([bool forceExit = false]) {
    _completer.complete(forceExit);
    _listeningKeys = false;
  }

  @override
  void tick() {
    if (!_listeningKeys) {
      return;
    }

    var key = console.readKey();
    for (var listener in _additionalListeners.keys) {
      if (!listener(key)) {
        _complete(true); // TODO: Previously `true`
        _additionalListeners[listener]?.call();
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

class InputBreakException {}
