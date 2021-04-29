import 'dart:async';
import 'dart:io';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/component/destroyable.dart';
import 'package:ondemand_terminal/console/component/number_field.dart';
import 'package:ondemand_terminal/console/component/selectable_list.dart';
import 'package:ondemand_terminal/console/console_util.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand_terminal/console/input_loop.dart';
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
  void initialNav(_) => context.breadcrumb.trailAdd('Welcome');

  @override
  FutureOr<void> display(Map<String, dynamic> payload) async {
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

    var timeOptional = await placeTime.displayOne();
    if (timeOptional.error) {
      throw InputBreakException();
    }
    var time = timeOptional.value;
    placeTime.destroy();

    context.console.console.cursorPosition = timePosition;

    print('1time= $time');
    if (time == OrderPlaceTime.FIND) {
      var timeResult = await navigator.routeToName<OrderPlaceTime>('time_selection', {'position': timePosition});
      if (timeResult.error) {
        throw InputBreakException();
      }

      time = timeResult.value;
    }

    print('2time = $time');

    print('EXITING!');
    exit(0);

    // Clear the top text too
    clearView(console, timePosition, context.mainPanelWidth, lineHeight + 1);

    // Why is this here??
    console.cursorPosition = timePosition;

    return navigator.routeToName('list_places', {'time': time});
  }

  @override
  void destroy() async {
    current.destroy();
    clearView(console, timePosition, context.mainPanelWidth, lineHeight + 1);
  }
}
