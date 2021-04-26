import 'dart:async';
import 'dart:math';

import 'package:dart_console/dart_console.dart';
import 'package:meta/meta.dart';
import 'package:ondemand_terminal/console/component/destroyable.dart';
import 'package:ondemand_terminal/console/input_loop.dart';

import '../../console.dart';
import '../console_util.dart';
import 'package:ondemand_terminal/extensions.dart';

class NumberField with Destroyable {
  final Coordinate position;

  final int width;

  final int minValue;

  final int maxValue;

  final ConsoleColor numberColor;

  final ConsoleColor plusColor;

  final ConsoleColor minusColor;

  /// The prompt that is shown at the top
  final String upperDescription;

  /// The prompt that is shown at the bottom
  final String lowerDescription;

  /// The [Console] object.
  final Console console;

  final InputLoop inputLoop;

  /// The active cursor position, used for resetting.
  Coordinate _cursor;

  int _value;

  NumberField(
      {@required this.console,
        @required this.inputLoop,
      this.position,
        this.width,
      this.minValue = 0,
      this.maxValue = 99,
      this.upperDescription,
      this.lowerDescription,
        this.numberColor = ConsoleColor.brightGreen,
        this.plusColor = ConsoleColor.brightGreen,
        this.minusColor = ConsoleColor.red,
      int initialValue = 0})
    : _value = initialValue;

  /// Displays the list, and when everything is selected, [callback] is invoked
  /// once.
  Future<int> display() async {
    _redisplay();

    await inputLoop.listen((key) {
      if (key.controlChar == ControlCharacter.backspace) {
        _value = (_value / 10).floor();
      } else if (key.controlChar == ControlCharacter.ctrlH) { // Ctrl + Backspace
        _value = 0;
      }  else if (key.controlChar == ControlCharacter.arrowUp || key.controlChar == ControlCharacter.arrowRight) {
        _value++;
      }  else if (key.controlChar == ControlCharacter.arrowDown || key.controlChar == ControlCharacter.arrowLeft) {
        _value--;
      } else if (!key.isControl && '1234567890'.contains(key.char)) {
        _value *= 10;
        _value += key.char.parseInt();
      }

      _value = min(max(_value, minValue), maxValue);

      _redisplay();
      return true;
    }, breakOn: [ControlCharacter.enter]);

    return _value;
  }

  @override
  void destroy() =>
      clearView(console, _cursor, width, _cursor.row - position.row + 1);

  void _redisplay() {
    console.cursorPosition = position;

    var upperLines = printText(upperDescription, false);

    void drawArrow(String char, ConsoleColor color) {
      console.setForegroundColor(ConsoleColor.brightBlack);
      console.write('[');
      console.setForegroundColor(color);
      console.write(char);
      console.setForegroundColor(ConsoleColor.brightBlack);
      console.write(']');
    }

    console.eraseLine();

    drawArrow('-', minusColor);

    console.setForegroundColor(numberColor);
    console.write(' $_value ');

    drawArrow('+', plusColor);

    console.writeLine();

    console.resetColorAttributes();
    var lowerLines = printText(lowerDescription, true);

    _cursor = position.add(
        row: upperLines + lowerLines + 2, col: lowerDescription?.length ?? 0);
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
