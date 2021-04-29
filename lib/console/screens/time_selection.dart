import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/component/destroyable.dart';
import 'package:ondemand_terminal/console/component/selectable_list.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand_terminal/console/input_loop.dart';
import 'package:ondemand_terminal/console/logic.dart';
import 'package:ondemand_terminal/console/time_handler.dart';
import 'package:ondemand_terminal/enums.dart';

class TimeSelection extends Navigation {
  final OnDemandConsole base;
  final Console console;
  final OnDemandLogic logic;

  Destroyable current;
  Coordinate timePosition;
  int lineHeight;

  TimeSelection(Navigator navigator, Context context)
      : base = context.console,
        console = context.console.console,
        logic = context.logic,
        super(navigator, context);

  @override
  void initialNav(_) => context.breadcrumb.trailAdd('Time Selection');

  @override
  FutureOr<OrderPlaceTime> display(Map<String, dynamic> payload) async {
    var position = payload['position'] as Coordinate;

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

    var timeOptional = await timeSelect.displayOne();
    if (timeOptional.error) {
      throw InputBreakException();
    }
    var time = timeOptional.value;
    print('time = $time'); // this should see an InputBreakException!
    timeSelect.destroy();

    context.breadcrumb.trailPop();

    return OrderPlaceTime.fromTime(time);
  }

  @override
  void destroy() async {
    context.breadcrumb.trailPop();
    current.destroy();
  }
}
