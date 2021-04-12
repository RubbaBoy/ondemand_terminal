import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand/base.dart';
import 'package:ondemand/helper/kitchen_helper.dart';
import 'package:ondemand/ondemand.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/component/option_managers.dart';
import 'package:ondemand_terminal/console/component/tiled_selection.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand_terminal/console/logic.dart';
import 'package:ondemand/get_items.dart' as _get_items;

class ListItems extends Navigation {
  final OnDemandConsole base;
  final Console console;
  final OnDemandLogic logic;

  TiledSelection<_get_items.FoodItem> tile;

  ListItems(Navigator navigator, Context context)
      : base = context.console,
        console = context.console.console,
        logic = context.logic,
        super(navigator, context);

  @override
  FutureOr<void> display(Map<String, dynamic> payload) async {
    var category = payload['category'] as Categories;
    var menuResponse = payload['menuResponse'] as MenuResponse;

    var items = await base.submitTask(logic.getItems(menuResponse.place, category));

    tile = TiledSelection<_get_items.FoodItem>(console: console, position: context.startContent,
      items: items,
      optionManager: StringOptionManager((option) => option.value.displayText),
      tileWidth: (context.mainPanelWidth / 4).floor(),
      tileHeight: 6,
      containerWidth: context.mainPanelWidth,
    );

    var item = await tile.showFuture();

    // If childGroups is FILLED, do get_item request (childGroups#id is the id of something idk)
    if (item.childGroups.isNotEmpty) {

    }
  }

  @override
  void destroy() => tile.destroy();
}