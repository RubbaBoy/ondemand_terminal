import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:ondemand/get_kitchens.dart' as _get_kitchens;
import 'package:dart_console/dart_console.dart';
import 'package:intl/intl.dart';
import 'package:ondemand/get_revenue_category.dart';
import 'package:ondemand/ondemand.dart';
import 'package:ondemand/get_menus.dart' as _get_menus;
import 'package:ondemand/get_items.dart' as _get_items;
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand_terminal/console/screens/list_categories.dart';
import 'package:ondemand_terminal/console/screens/list_items.dart';
import 'package:ondemand_terminal/console/screens/list_places.dart';
import 'package:ondemand_terminal/console/screens/welcome.dart';

import 'console/breadcrumb.dart';
import 'console/cart.dart';
import 'console/component/base.dart';
import 'console/component/option_managers.dart';
import 'console/component/selectable_list.dart';
import 'console/component/tiled_selection.dart';
import 'console/console_util.dart';
import 'console/loading.dart';
import 'console/logic.dart';
import 'console/time_handler.dart';
import 'enums.dart';

final money = NumberFormat('#,##0.00', 'en_US');

List<String> specialSplit(String string, String splitting) {
  var out = <String>[];
  int index;
  var start = 0;
  while ((index = string.indexOf(splitting, start)) != -1) {
    if (start != index) {
      out.add(string.substring(start, index));
    }

    out.add(string.substring(index, index + splitting.length));
    start = index + splitting.length;
  }
  out.add(string.substring(start));
  return out;
}

class OnDemandConsole {

  Loading loading;

  static const startContent = Coordinate(5, 0);

  final logic = OnDemandLogic();

  final Console console = Console();

  Future<void> show() async {
    var height = console.windowHeight;
    var width = console.windowWidth;

    console.clearScreen();
    console.setForegroundColor(ConsoleColor.brightRed);
    console.writeLine('RIT OnDemand Terminal', TextAlignment.center);
    console.setForegroundColor(ConsoleColor.white);
    console.writeLine('by Adam Yarris', TextAlignment.center);
    console.resetColorAttributes();

    console.writeLine();

    loading = Loading(console, Coordinate(3, (width / 2).floor() - 10), 20);

    console.cursorPosition = Coordinate(height - 2, 1);
    console.write('(c) 2021 Adam Yarris');

    var size = '${width}x$height';
    console.cursorPosition = Coordinate(height - 2, width - size.length);
    console.write(size);

    console.cursorPosition = startContent;

    var cart = Cart(console, []);
    cart.showCart();

    console.cursorPosition = startContent;

    var breadcrumb = Breadcrumb(
        console: console,
        position: startContent.sub(row: 2),
        resetPosition: startContent,
        trail: []);
    breadcrumb.update();

    var mainPanelWidth = max(width - cart.width, (width * 0.75).floor()) - 5;

    await submitTask(init());

    var context = Context(this, logic, breadcrumb, mainPanelWidth, startContent);

    final nav = Navigator(context);
    nav.addRoute('welcome', () => Welcome(nav, context));
    nav.addRoute('list_places', () => ListPlaces(nav, context));
    nav.addRoute('list_categories', () => ListCategories(nav, context));
    nav.addRoute('list_items', () => ListItems(nav, context));

    await nav.routeToName('welcome');

    close(console);
  }

  Future<void> init() async => await logic.init();

  Future<T> submitTask<T>(Future<T> future) {
    loading.start();
    return future.then((value) {
      loading.stop();
      console.resetColorAttributes();
      console.cursorPosition = startContent;
      return value;
    });
  }
}

class Context {
  final OnDemandConsole console;
  final OnDemandLogic logic;
  final Breadcrumb breadcrumb;
  final int mainPanelWidth;
  final Coordinate startContent;

  Context(this.console, this.logic, this.breadcrumb, this.mainPanelWidth, this.startContent);
}

List<FormattedString> wrapFormattedStringList(List<FormattedString> strings, int width, [int prefixChars = 0]) {
  var formatted = <FormattedString>[];
  for (var formatString in strings) {
    formatted.addAll(wrapStringList(formatString.value, width, prefixChars)
        .map((str) => FormattedString(str, formatString.asciiFormatting)));
  }
  return formatted;
}

List<String> wrapStringList(String string, int width, [int prefixChars = 0]) {
  // No newline splitting is intentional
  var splitWords = string
      .split(' ')
      .map((e) => specialSplit(e, '\n'))
      .reduce((a, b) => [...a, ...b])
      .toList();
  var doneLines = <String>[];
  var currLine = '';
  while (splitWords.isNotEmpty) {
    var word = splitWords.removeAt(0);

    if (word == '\n') {
      doneLines.add(currLine);
      currLine = '';
      continue;
    }

    if (word.length + prefixChars > width) {
      doneLines.add(currLine);
      doneLines.add(word);
      currLine = '';
    } else if (currLine.length + word.length + prefixChars < width) {
      currLine += ' $word';
    } else {
      doneLines.add(currLine);
      currLine = word;
    }
  }

  if (currLine.isNotEmpty) {
    doneLines.add(currLine);
  }

  return doneLines.map((e) => e.trim()).toList();
}

String wrapString(String string, int width, [int prefixChars = 0]) {
  var doneLines = wrapStringList(string, width, prefixChars);
  var str = doneLines.first.trim();
  if (doneLines.length > 1) {
    str += '\n${doneLines.skip(1).map((line) => '${' ' * prefixChars}${line.trim()}').join('\n')}';
  }
  return str;
}

String truncateString(String text, int length) =>
    length < text.length ? text.substring(0, length) : text;

void cursorDown(Console console, int amount) {
  for (var i = 0; i < amount; i++) {
    console.cursorDown();
  }
}

/// Clears the view and resets the cursor to [position]. [height] is inclusive.
void clearView(Console console, Coordinate bottom, int width, int height) {
  var bottomLeft = bottom.copy(col: 0);
  console.cursorPosition = bottomLeft;
  for (var i = 0; i <= height; i++) {
    console.write(' ' * width);
    console.cursorPosition = bottomLeft = bottomLeft.sub(row: 1);
  }
}

void close(Console console, [String message]) {
  if (message != null) {
    console.clearScreen();
    console.write(message);
  }
  console.resetCursorPosition();
  console.rawMode = false;
  exit(1);
}
