import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand/ondemand.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/component/tiled_selection.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand/get_items.dart' as _get_items;
import 'package:ondemand_terminal/console/logic.dart';

/// If an item requires special stuff like toppings, this is shown
class ItemOption extends Navigation {
  final OnDemandConsole base;
  final Console console;
  final OnDemandLogic logic;

  TiledSelection<dynamic> tile;

  ItemOption(Navigator navigator, Context context)
      : base = context.console,
        console = context.console.console,
        logic = context.logic,
        super(navigator, context);

  /// Returns the [SelectedModifiers].
  @override
  FutureOr<List<SelectedModifiers>> display(Map<String, dynamic> payload) {
    var item = payload['item'] as _get_items.FoodItem;

    var gotItem = logic.getItem(item);


  }

  @override
  void destroy() => tile.destroy();
}