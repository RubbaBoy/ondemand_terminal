import 'package:dart_console/dart_console.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/component/option_managers.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand_terminal/console/logic.dart';
import 'package:ondemand_terminal/enums.dart';

import '../component/tiled_selection.dart';

class ListPlaces extends Navigation {
  final OnDemandConsole base;
  final Console console;
  final OnDemandLogic logic;

  TiledSelection<KitchenSelector> tile;

  ListPlaces(Navigator navigator, Context context)
      : base = context.console,
        console = context.console.console,
        logic = context.logic,
        super(navigator, context);

  @override
  void initialNav(_) => context.breadcrumb.trailAdd('Kitchen Select');

  @override
  Future<void> display(Map<String, dynamic> payload) async {
    var time = payload['time'] as OrderPlaceTime;

    var kitchens = await base.submitTask(logic.getKitchens());

    tile = TiledSelection<KitchenSelector>(
      console: base.console,
      inputLoop: context.inputLoop,
      position: context.startContent,
      items: kitchens.map((e) => KitchenSelector(e, time)).toList(),
      optionManager: const KitchenOptionManager(),
      tileWidth: (context.mainPanelWidth / 4).floor(),
      tileHeight: 6,
      containerWidth: context.mainPanelWidth,
    );

    var kitchenSelector = await tile.showFuture();

    context.breadcrumb.trailPop();

    return navigator
        .routeToName('list_categories', {'kitchen': kitchenSelector});
  }

  @override
  void destroy() async {
    tile.destroy();
    context.breadcrumb.trailPop();
  }
}
