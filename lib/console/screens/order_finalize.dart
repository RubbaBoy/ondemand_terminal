import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand/get_item.dart' as _get_item;
import 'package:ondemand/get_items.dart' as _get_items;
import 'package:ondemand/ondemand.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/component/destroyable.dart';
import 'package:ondemand_terminal/console/component/number_field.dart';
import 'package:ondemand_terminal/console/component/option_managers.dart';
import 'package:ondemand_terminal/console/component/selectable_list.dart';
import 'package:ondemand_terminal/console/component/text_field.dart';
import 'package:ondemand_terminal/console/component/tiled_selection.dart';
import 'package:ondemand_terminal/console/console_util.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand_terminal/console/logic.dart';

/// If an item requires special stuff like toppings, this is shown
class OrderFinalize extends Navigation {
  final OnDemandConsole base;
  final Console console;
  final OnDemandLogic logic;

  int lineHeight;
  Destroyable current;
  Coordinate timePosition;

  OrderFinalize(Navigator navigator, Context context)
      : base = context.console,
        console = context.console.console,
        logic = context.logic,
        super(navigator, context);

  /// Returns the [SelectedModifiers].
  @override
  FutureOr<OrderFinalizeResult> display(
      Map<String, dynamic> payload) async {
    var item = payload['item'] as _get_items.FoodItem;

    lineHeight = base.writeLines(
        'Just finalizing your selection of: ${item.displayText}',
        context.mainPanelWidth);

    timePosition = context.startContent.add(row: lineHeight + 1);

    var allergyField = current = TextField(
        console: console,
        inputLoop: context.inputLoop,
        position: timePosition,
        width: context.mainPanelWidth,
        upperDescription: 'List any allergies:');
    var allergies = await allergyField.displayFuture();

    var field = current = NumberField(
        console: console,
        inputLoop: context.inputLoop,
        position: timePosition,
        width: context.mainPanelWidth,
        upperDescription: 'Count:');
    var count = await field.displayFuture();

    // Clear the top text too
    clearView(console, timePosition, context.mainPanelWidth, lineHeight + 1);

    console.cursorPosition = timePosition;

    return OrderFinalizeResult(count, allergies);
  }

  @override
  void destroy() => current?.destroy();
}

class OrderFinalizeResult {
  final int count;
  final String allergies;

  OrderFinalizeResult(this.count, this.allergies);
}
