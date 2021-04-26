import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/component/destroyable.dart';
import 'package:ondemand_terminal/console/component/number_field.dart';
import 'package:ondemand_terminal/console/component/selectable_list.dart';
import 'package:ondemand_terminal/console/console_util.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand_terminal/console/logic.dart';
import 'package:ondemand_terminal/console/time_handler.dart';
import 'package:ondemand_terminal/enums.dart';

class Welcome extends Navigation {
  final OnDemandConsole base;
  final Console console;
  final OnDemandLogic logic;

  Destroyable current;
  Coordinate timePosition;
  int lineHeight;

  Welcome(Navigator navigator, Context context)
      : base = context.console,
        console = context.console.console,
        logic = context.logic,
        super(navigator, context);

  @override
  FutureOr<void> display(Map<String, dynamic> payload) async {
    context.breadcrumb.trailAdd('Welcome');

    lineHeight = base.writeLines(
        '''Welcome to the RIT OnDemand Terminal! The goal of this is to fully utilize the RIT OnDemand through the familiarity of your terminal.
To select menu items, use arrow keys to navigate, space to select, and enter to finalize. Press End to go back a page.''',
        context.mainPanelWidth);

    timePosition = context.startContent.add(row: lineHeight + 1);

    var placeTime = current = SelectableList<OrderPlaceTime>(
        console: console,
        inputLoop: context.inputLoop,
        upperDescription: 'Please select a time for your order:',
        position: timePosition,
        width: context.mainPanelWidth,
        items: OrderPlaceTime.values,
        multi: false,
        autoSelect: true);

    var time = await placeTime.displayOneFuture();
    placeTime.destroy();

    context.console.console.cursorPosition = timePosition;

    if (time == OrderPlaceTime.FIND) {
      time = await showTimes(timePosition);
    }

    // Clear the top text too
    clearView(console, timePosition, context.mainPanelWidth, lineHeight + 1);

    // Why is this here??
    console.cursorPosition = timePosition;

    return navigator.routeToName('list_places', {'time': time});
  }

  Future<OrderPlaceTime> showTimes(Coordinate position) async {
    final completer = Completer<OrderTime>();
    var times = await base.submitTask(logic.getOrderTimes());

    var timeSelect = current = SelectableList<OrderTime>(
        console: console,
        inputLoop: context.inputLoop,
        position: position,
        upperDescription: 'Please select a time for your order:',
        width: context.mainPanelWidth,
        items: times,
        multi: false,
        autoSelect: true,
        scrollAfter: 15);

    var time = await timeSelect.displayOneFuture();
    timeSelect.destroy();
    completer.complete(time);

    return completer.future.then((time) => OrderPlaceTime.fromTime(time));
  }

  @override
  void destroy() async {
    current.destroy();
    clearView(console, timePosition, context.mainPanelWidth, lineHeight + 1);
  }
}
