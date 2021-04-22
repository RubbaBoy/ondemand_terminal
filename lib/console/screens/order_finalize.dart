import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand/ondemand.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/component/option_managers.dart';
import 'package:ondemand_terminal/console/component/selectable_list.dart';
import 'package:ondemand_terminal/console/component/tiled_selection.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand/get_items.dart' as _get_items;
import 'package:ondemand/get_item.dart' as _get_item;
import 'package:ondemand_terminal/console/logic.dart';
import 'package:ondemand_terminal/console/console_util.dart';

/// If an item requires special stuff like toppings, this is shown
class OrderFinalize extends Navigation {
  final OnDemandConsole base;
  final Console console;
  final OnDemandLogic logic;

  int lineHeight;
  SelectableList<_get_item.ChildItems> currentList;
  Coordinate timePosition;

  OrderFinalize(Navigator navigator, Context context)
      : base = context.console,
        console = context.console.console,
        logic = context.logic,
        super(navigator, context);

  /// Returns the [SelectedModifiers].
  @override
  FutureOr<List<SelectedModifiers>> display(Map<String, dynamic> payload) async {
    // var item = payload['item'] as _get_items.FoodItem;
    //
    // var gotItem = await base.submitTask(logic.getItem(item));
    //
    // lineHeight = base.writeLines('Select options for "${item.displayText}"',
    //     context.mainPanelWidth);
    //
    // timePosition = context.startContent.add(row: lineHeight + 1);
    //
    // var modifiers = <SelectedModifiers>[];
    //
    // for (var child in gotItem.childGroups) {
    //   modifiers.add(await selectChildGroup(timePosition, child));
    // }
    //
    // // Clear the top text too
    // clearView(console, timePosition, context.mainPanelWidth, lineHeight + 1);
    //
    // console.cursorPosition = timePosition;
    //
    // return modifiers;
  }

  @override
  void destroy() => currentList.destroy();
}

class OrderFinalizeResult {
  final int count;
  final String allergies;

  OrderFinalizeResult(this.count, this.allergies);
}
