import 'dart:async';

import 'package:dart_console/dart_console.dart';
import 'package:ondemand/base.dart';
import 'package:ondemand/get_items.dart' as _get_items;
import 'package:ondemand/helper/kitchen_helper.dart';
import 'package:ondemand/ondemand.dart';
import 'package:ondemand_terminal/console.dart';
import 'package:ondemand_terminal/console/component/option_managers.dart';
import 'package:ondemand_terminal/console/component/tiled_selection.dart';
import 'package:ondemand_terminal/console/console_util.dart';
import 'package:ondemand_terminal/console/history.dart';
import 'package:ondemand_terminal/console/input_loop.dart';
import 'package:ondemand_terminal/console/logic.dart';
import 'package:ondemand_terminal/console/screens/order_finalize.dart';
import 'package:ondemand_terminal/extensions.dart';

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
  void initialNav(Map<String, dynamic> payload) =>
      context.breadcrumb.trailAdd(payload['category'].name);

  @override
  FutureOr<void> display(Map<String, dynamic> payload) async {
    var category = payload['category'] as Categories;
    var kitchenSelector = payload['kitchen'] as KitchenSelector;
    var menuResponse = payload['menuResponse'] as MenuResponse;

    var items =
        await base.submitTask(logic.getItems(menuResponse.place, category));

    tile = TiledSelection<_get_items.FoodItem>(
      console: console,
      inputLoop: context.inputLoop,
      position: context.startContent,
      items: items,
      optionManager: StringOptionManager((option) => option.value.displayText),
      tileWidth: (context.mainPanelWidth / 4).floor(),
      tileHeight: 6,
      containerWidth: context.mainPanelWidth,
    );

    var itemOptional = await tile.display();
    if (itemOptional.error) {
      throw InputBreakException();
    }
    var item = itemOptional.value;

    // If childGroups is FILLED, do get_item request (childGroups#id is the id of something idk)
    List<SelectedModifiers> modifiers;
    if (item.childGroups.isNotEmpty) {
      var modifierResult = await navigator.routeToName<List<SelectedModifiers>>('item_option', {'item': item});
      if (modifierResult.error) {
        return;
      }
      modifiers = modifierResult.value;
    }

    var finalizeResult = await navigator.routeToName<OrderFinalizeResult>('order_finalize', {'item': item});
    if (finalizeResult.error) {
      return;
    }

    var finalize = finalizeResult.value;

    await logic.addItemToOrder(
        kitchenSelector.kitchen,
        foodItemToItem(
            item, modifiers, finalize.count, finalize.allergies),
        kitchenSelector.time);
  }

  @override
  void destroy() {
    context.breadcrumb.trailPop();
    tile.destroy();
  }

  Item foodItemToItem(_get_items.FoodItem item,
      List<SelectedModifiers> selectedModifiers, int count, String allergies) {
    var guid = '${item.id}-${DateTime.now().millisecondsSinceEpoch}';
    return Item(
      id: item.id,
      contextId: item.contextId,
      tenantId: item.tenantId,
      itemId: item.itemId,
      name: item.name,
      isDeleted: item.isDeleted,
      isActive: item.isActive,
      lastUpdateTime: item.lastUpdateTime,
      revenueCategoryId: item.revenueCategoryId,
      productClassId: item.productClassId,
      kpText: item.kpText,
      kitchenDisplayText: item.kitchenDisplayText,
      receiptText: item.receiptText,
      price: item.price,
      defaultPriceLevelId: item.defaultPriceLevelId,
      priceLevels: item.priceLevels,
      isSoldByWeight: item.isSoldByWeight,
      tareWeight: item.tareWeight,
      isDiscountable: item.isDiscountable,
      allowPriceOverride: item.allowPriceOverride,
      isTaxIncluded: item.isTaxIncluded,
      taxClasses: item.taxClasses,
      kitchenVideoLabel: item.kitchenVideoLabel,
      kitchenVideoId: item.kitchenVideoId,
      kitchenVideoCategoryId: item.kitchenVideoCategoryId,
      kitchenCookTimeSeconds: item.kitchenCookTimeSeconds,
      skus: item.skus,
      itemType: item.itemType,
      displayText: item.displayText,
      itemImages: item.itemImages,
      isAvailableToGuests: item.isAvailableToGuests,
      isPreselectedToGuests: item.isPreselectedToGuests,
      tagNames: item.tagNames,
      tagIds: item.tagIds,
      substituteItemId: item.substituteItemId,
      isSubstituteItem: item.isSubstituteItem,
      properties: CartProperties(cartGuid: guid),
      amount: item.amount,
      image: item.image,
      thumbnail: item.thumbnail,
      options: item.options,
      attributes: item.attributes,
      conceptId: item.conceptId,
      count: count,
      quantity: count,
      selectedModifiers: selectedModifiers,
      splInstruction: allergies,
      modifierTotal: selectedModifiers
          .map((e) => e.amount?.parseInt() ?? 0)
          .reduce((a, b) => a + b),
      // TODO: Unsure if `amount` is right
      mealPeriodId: null,
      uniqueId: guid,
      cartItemId: uuid.v4(), // TODO: I think this is auto generated?
    );
  }
}
