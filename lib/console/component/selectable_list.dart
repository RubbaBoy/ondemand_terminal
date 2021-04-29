import 'dart:async';
import 'dart:math' as math;

import 'package:dart_console/dart_console.dart';
import 'package:meta/meta.dart';
import 'package:ondemand_terminal/console/component/destroyable.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand_terminal/console/input_loop.dart';
import 'package:ondemand_terminal/extensions.dart';

import '../../console.dart';
import '../console_util.dart';
import 'base.dart';
import 'option_managers.dart';

class SelectableList<T> with Destroyable {
  final Coordinate position;

  final int width;

  /// Will enable scrolling after the given amount of lines (or until the end
  /// of the screen is reached)
  final int scrollAfter;

  /// If [true], this will act as a checkbox. If [false], it will act as a
  /// radio.
  final bool multi;

  /// The minimum amount of items that may be selected.
  final int min;

  /// The maximum amount of items that may be selected
  final int max;

  /// If the first item should be automatically selected
  final bool autoSelect;

  /// The items being displayed. [toString()] is invoked on [T] to display
  /// in the console.
  final List<Option<T>> items;

  /// The prompt that is shown at the top
  final String upperDescription;

  /// The prompt that is shown at the bottom
  final String lowerDescription;

  /// The [Console] object.
  final Console console;

  final InputLoop inputLoop;

  final OptionManager<T> optionManager;

  /// The list index the cursor is at
  int index = 0;

  /// The active cursor position, used for resetting.
  Coordinate _cursor;

  /// If scrolling is used
  final bool scrolling;

  /// The top index
  int scrollFrom = 0;

  /// The bottom index
  int scrollTo = 0;

  SelectableList._(
      this.console,
      this.inputLoop,
      this.position,
      this.optionManager,
      this.width,
      this.scrollAfter,
      this.items,
      this.lowerDescription,
      this.upperDescription,
      this.multi,
      this.min,
      this.max,
      this.autoSelect,
      this.scrolling,
      this.scrollTo);

  factory SelectableList(
      {@required Console console,
      @required InputLoop inputLoop,
      Coordinate position,
      OptionManager<T> optionManager,
      int width,
      int scrollAfter,
      @required List<T> items,
      String lowerDescription,
      String upperDescription,
      bool multi = true,
      int min = 0,
      int max = 1,
      bool autoSelect = false}) {
    optionManager ??= DefaultOptionManager<T>();
    var _items = items.map(optionManager.createOption).toList();
    scrollAfter ??= double.maxFinite.toInt();

    if (autoSelect) {
      _items.first.selected = true;
    }

    var _scrolling = items.length > scrollAfter;
    var _scrollTo = math.min(items.length, scrollAfter);

    return SelectableList._(
        console,
        inputLoop,
        position,
        optionManager,
        width,
        scrollAfter,
        _items,
        lowerDescription,
        upperDescription,
        multi,
        min,
        max,
        autoSelect,
        _scrolling,
        _scrollTo);
  }

  /// Same as [#display(void Function())] but only takes the first
  /// element from the result (or null).
  Future<Optional<T>> displayOne() => display().then(
      (value) => value.transform((list) => list.isEmpty ? null : list.first));

  /// Displays the list, and when everything is selected, [callback] is invoked
  /// once.
  Future<Optional<List<T>>> display() async {
    _redisplay();

    /// 0 is no wrapping occurred
    /// 1 if a wrap to 0 occurred
    /// -1 is a wrapped to `length - 1` occurred
    int processIndex() {
      if (index > items.length - 1) {
        index = 0;
        return 1;
      } else if (index < 0) {
        index = items.length - 1;
        return -1;
      }
      return 0;
    }

    /// Returns if a wrap occurred
    bool processWrapIndex() {
      var wrap = processIndex();

      var diff = scrollTo - scrollFrom;
      if (wrap == 1) {
        scrollFrom = 0;
        scrollTo = diff;
        return true;
      } else if (wrap == -1) {
        scrollTo = items.length;
        scrollFrom = scrollTo - diff;
        return true;
      }

      return false;
    }

    return inputLoop.listen((key) {
      if (key.controlChar == ControlCharacter.arrowUp) {
        index--;
        if (!processWrapIndex() && scrolling && index + 1 == scrollFrom) {
          scrollFrom--;
          scrollTo--;
        }
      } else if (key.controlChar == ControlCharacter.arrowDown) {
        index++;
        if (!processWrapIndex() && scrolling && index == scrollTo) {
          scrollFrom++;
          scrollTo++;
        }
      } else if (key.char == ' ') {
        if (multi) {
          if (items[index].selected) {
            items[index].selected = false;
          } else if (amountSelected() < max) {
            items[index].selected = true;
          }
        } else {
          var selected = getSelected();
          if (selected.isNotEmpty) {
            selected.first.selected = false;
          }

          items[index].selected = true;
        }
      } else if (key.controlChar == ControlCharacter.enter) {
        var selected = getSelected().length;
        if (selected >= min && selected <= max) {
          return false;
        }
      } else if (key.controlChar == ControlCharacter.ctrlC) {
        close(console, 'Terminal closed by user');
      }

      _redisplay();
      return true;
    }).componentValue(
        () => getSelected().map((option) => option.value).toList());
  }

  @override
  void destroy() =>
      clearView(console, _cursor, width, _cursor.row - position.row + 1);

  int amountSelected() => getSelected().length;

  List<Option<T>> getSelected() =>
      items.where((option) => option.selected).toList();

  void _redisplay() {
    console.cursorPosition = position;

    var upperLines = printText(upperDescription, false);

    var row = 0;
    for (var i = scrollFrom; i < scrollTo; i++) {
      var value = items[i];
      console.setForegroundColor(ConsoleColor.brightBlack);
      console.write('[');
      console.setForegroundColor(
          value.selected ? ConsoleColor.brightGreen : ConsoleColor.red);
      console.write(index == i ? '-' : 'x');
      console.setForegroundColor(ConsoleColor.brightBlack);
      console.write('] ');
      console.resetColorAttributes();

      // TODO: Allow for formatting!
      var wrapped = wrapString(
          optionManager
              .displayFormattedString(value)
              .map((e) => e.value)
              .join('\n'),
          width,
          4);
      console.write(wrapped);
      console.writeLine();

      row += wrapped.split('\n').length;
    }

    var lowerLines = printText(lowerDescription, true);

    _cursor = position.add(
        row: row + upperLines + lowerLines, col: lowerDescription?.length ?? 0);
  }

  /// Prints test, returning a list of the used newlines;
  int printText(String test, bool newlineBefore) {
    var descriptionLines = 0;
    if (test != null) {
      var printingDesc = wrapString(test, width);
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
