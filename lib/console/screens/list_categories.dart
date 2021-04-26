import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand/base.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/component/option_managers.dart';
import 'package:ondemand_terminal/console/component/tiled_selection.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand_terminal/console/logic.dart';

class ListCategories extends Navigation {
  final OnDemandConsole base;
  final Console console;
  final OnDemandLogic logic;

  TiledSelection<Categories> tile;

  ListCategories(Navigator navigator, Context context)
      : base = context.console,
        console = context.console.console,
        logic = context.logic,
        super(navigator, context);

  @override
  void initialNav(Map<String, dynamic> payload) =>
      context.breadcrumb.trailAdd(payload['kitchen'].kitchen.name);

  @override
  FutureOr<void> display(Map<String, dynamic> payload) async {
    var kitchenSelector = payload['kitchen'] as KitchenSelector;

    var menuResponse = await base.submitTask(logic.getMenu(kitchenSelector));

    tile = TiledSelection<Categories>(console: console,
      inputLoop: context.inputLoop,
      position: context.startContent,
      items: menuResponse.menu.categories,
      optionManager: StringOptionManager((option) => option.value.name),
      tileWidth: (context.mainPanelWidth / 4).floor(),
      tileHeight: 6,
      containerWidth: context.mainPanelWidth,
    );

    var category = await tile.display();

    return navigator.routeToName('list_items', {'category': category, 'menuResponse': menuResponse, 'kitchen': kitchenSelector});
  }

  @override
  void destroy() {
    tile.destroy();
    context.breadcrumb.trailPop();
  }
}