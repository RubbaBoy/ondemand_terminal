import 'dart:async';
import 'dart:math';

import 'package:dart_console/dart_console.dart';
import 'package:meta/meta.dart';

import '../../console.dart';
import '../console_util.dart';

class TextField {
  static final WORD_BACKSPACE = RegExp(r'(.*\s+)([^\s]+)');

  final Coordinate position;

  final int width;

  /// The max length of text
  final int maxLength;

  /// The prompt that is shown at the top
  final String upperDescription;

  /// The prompt that is shown at the bottom
  final String lowerDescription;

  /// The [Console] object.
  final Console console;

  /// The active cursor position, used for resetting.
  Coordinate _cursor;

  /// The text being typed
  String _text = '';

  TextField(
      {@required this.console,
      this.position,
      this.width,
      this.maxLength,
      this.upperDescription,
      this.lowerDescription});

  Future<String> displayFuture() {
    final completer = Completer<String>();
    display(completer.complete);
    return completer.future;
  }

  /// Displays the list, and when everything is selected, [callback] is invoked
  /// once.
  void display(void Function(String text) callback) {
    _redisplay();

    Key key;
    while ((key = console.readKey()) != null) {
      if (key.controlChar == ControlCharacter.enter) {
        break;
      } else if (key.controlChar == ControlCharacter.ctrlC) {
        close(console, 'Terminal closed by user');
      } else if (key.controlChar == ControlCharacter.backspace) {
        _text = _text.substring(0, max(0, _text.length - 1));
      } else if (key.controlChar == ControlCharacter.ctrlJ) { // Ctrl + Enter
        _text += '\n';
      } else if (key.controlChar == ControlCharacter.ctrlH) { // Ctrl + Backspace
        var match = WORD_BACKSPACE.firstMatch(_text);
        if ((match?.groupCount ?? 0) == 2) {
          _text = _text.substring(0, match
              .group(1)
              .length);
        } else if (_text.isNotEmpty) {
          _text = '';
        }
      } else if (!key.isControl && (maxLength == -1 || _text.length <= maxLength)) {
        _text += key.char;
      }

      _redisplay();
    }

    callback(_text);
  }

  void destroy() =>
      clearView(console, _cursor, width, _cursor.row - position.row + 1);

  void _redisplay() {
    console.cursorPosition = position;

    var upperLines = printText(upperDescription, false);

    var wrappedSplit = wrapString(_text, width, 0, false).split('\n');
    var wrapped = '';

    // Prevents clearing the line every time to remove excess underscores at the
    // end of previously written lines.
    for (var i = 0; i < wrappedSplit.length; i++) {
      var line = wrappedSplit[i];
      var char = i == wrappedSplit.length - 1 ? '_' : ' ';
      wrapped += '$line${char * (width - line.length)}\n';
    }

    console.write(wrapped);
    console.eraseLine();

    var row = wrappedSplit.length + 1;

    var lowerLines = printText(lowerDescription, true);

    _cursor = position.add(
        row: row + upperLines + lowerLines, col: lowerDescription?.length ?? 0);
  }

  /// Prints text, returning a list of the used newlines;
  int printText(String text, bool newlineBefore) {
    var descriptionLines = 0;
    if (text != null) {
      var printingDesc = wrapString(text, width);
      if (newlineBefore) {
        console.writeLine();
      }

      console.writeLine(printingDesc);

      if (!newlineBefore) {
        console.writeLine();
      }

      descriptionLines = printingDesc.split('\n').length;
    }
    return descriptionLines;
  }
}
