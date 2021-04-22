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
class ItemOption extends Navigation {
  final OnDemandConsole base;
  final Console console;
  final OnDemandLogic logic;

  int lineHeight;
  SelectableList<_get_item.ChildItems> currentList;
  Coordinate timePosition;

  ItemOption(Navigator navigator, Context context)
      : base = context.console,
        console = context.console.console,
        logic = context.logic,
        super(navigator, context);

  /// Returns the [SelectedModifiers].
  @override
  FutureOr<List<SelectedModifiers>> display(Map<String, dynamic> payload) async {
    var item = payload['item'] as _get_items.FoodItem;

    var gotItem = await base.submitTask(logic.getItem(item));

    lineHeight = base.writeLines('Select options for "${item.displayText}"',
        context.mainPanelWidth);

    timePosition = context.startContent.add(row: lineHeight + 1);

    var modifiers = <SelectedModifiers>[];

    for (var child in gotItem.childGroups) {
      modifiers.add(await selectChildGroup(timePosition, child));
    }

    // Clear the top text too
    clearView(console, timePosition, context.mainPanelWidth, lineHeight + 1);

    console.cursorPosition = timePosition;

    return modifiers;
  }

  Future<SelectedModifiers> selectChildGroup(Coordinate coordinate, _get_item.ChildGroup childGroup) async {
    var multi = !(childGroup.minimum == 1 && childGroup.maximum == 1);
    currentList = SelectableList<_get_item.ChildItems>(
        console: console,
        upperDescription: 'Please select a time for your order:',
        optionManager: StringOptionManager((option) => option.value.displayText),
        position: coordinate,
        width: context.mainPanelWidth,
        items: childGroup.childItems,
        multi: multi,
        min: childGroup.minimum,
        max: childGroup.maximum,
        autoSelect: !multi);

    var selectedItem = await currentList.displayOneFuture();
    currentList.destroy();

    return selectedItem != null ? modifierFromItem(childGroup, selectedItem) : null;
  }

  SelectedModifiers modifierFromItem(_get_item.ChildGroup childGroup, _get_item.ChildItems item) {
    return SelectedModifiers(
      id: item.id,
      description: item.name,
      selected: true,
      // TODO: idk
      baseAmount: '0.00',
      amount: '0.00',
      childPriceLevelId: PRICE_LEVEL,
      parentGroupId: childGroup.id,
      currencyUnit: CURRENCY,
    );
  }

  @override
  void destroy() => currentList.destroy();
}