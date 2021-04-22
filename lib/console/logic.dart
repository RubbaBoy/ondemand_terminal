import 'package:ondemand/base.dart';
import 'package:ondemand/get_config.dart' as _get_config;
import 'package:ondemand/get_item.dart' as _get_item;
import 'package:ondemand/get_items.dart' as _get_items;
import 'package:ondemand/get_kitchens.dart' as _get_kitchens;
import 'package:ondemand/add_cart.dart' as _add_cart;
import 'package:ondemand/add_cart_new.dart' as _add_cart_new;
import 'package:ondemand/helper/kitchen_helper.dart' as _kitchen_helper;
import 'package:ondemand/list_places.dart' as _list_places;
import 'package:ondemand/ondemand.dart';
import 'package:ondemand_terminal/console/component/option_managers.dart';
import 'package:ondemand_terminal/enums.dart';

import 'time_handler.dart';
import 'package:ondemand_terminal/extensions.dart';

class OnDemandLogic {
  OnDemand onDemand;
  _get_config.Response config;
  _get_kitchens.Response _kitchens;

  Future<void> init() async {
    onDemand = await Initialization.create();
    config = onDemand.config;
  }

  Future<_get_kitchens.Response> _getKitchens() async =>
      _kitchens ??= await onDemand.getKitchens(_get_kitchens.Request());

  Future<List<OrderTime>> getOrderTimes() async {
    Time minTime;
    Time maxTime;
    for (var kitchen in (await _getKitchens()).kitchens) {
      if (kitchen.availableAt.opens.isEmpty ||
          kitchen.availableAt.closes.isEmpty) {
        continue;
      }

      var opens = Time.fromString(kitchen.availableAt.opens);
      var closes = Time.fromString(kitchen.availableAt.closes);

      minTime ??= opens;
      maxTime ??= closes;

      if (isAfter(opens, minTime)) {
        minTime = opens;
      }

      if (isAfter(maxTime, closes)) {
        maxTime = closes;
      }
    }

    var scheduledOrdering = config.properties.scheduledOrdering;
    return calculateOrderTimes(minTime, maxTime, scheduledOrdering.intervalTime,
        scheduledOrdering.bufferTime);
  }

  Future<List<_get_kitchens.Kitchen>> getKitchens() async =>
      (await _getKitchens()).kitchens;

  Future<_kitchen_helper.MenuResponse> getMenu(KitchenSelector kitchenSelector) {
    var startTime, endTime;
    var time = kitchenSelector.time;
    if (time != OrderPlaceTime.ASAP) {
      startTime = '${time.time.start}';
      endTime = '${time.time.end}';
    }
    return _kitchen_helper.getMenu(
        onDemand, kitchenSelector.kitchen, startTime, endTime);
  }

  Future<List<_get_items.FoodItem>> getItems(
          _list_places.Place place, Categories categories) =>
      onDemand
          .getItems(_get_items.Request(
            conceptId: place.id,
            itemIds: categories.items,
            currencyUnit: CURRENCY,
            storePriceLevel: PRICE_LEVEL,
          ),
      contextId: config.contextID)
          .then((response) => response.items);

  Future<_get_item.Response> getItem(_get_items.FoodItem foodItem) =>
      onDemand.getItem(
          _get_item.Request(
            storePriceLevel: PRICE_LEVEL,
            currencyUnit: CURRENCY,
          ),
          contextId: config.contextID,
          itemID: foodItem.id);

  String _orderId;

  final currencyDetails = CurrencyDetails(
    currencyDecimalDigits: '2',
    currencyCultureName: 'en-US',
    currencyCode: 'USD',
    currencySymbol: r'$',
  );

  Future<_add_cart_new.OrderDetails> addItemToOrder(_get_kitchens.Kitchen kitchen, Item item, OrderPlaceTime orderPlaceTime) {
    if (_orderId == null) {
      return onDemand.addCartNew(_add_cart_new.Request(
          item: item,
          currencyDetails: currencyDetails,
          schedule: null,
          scheduleTime: orderPlaceTime.toScheduleTime(),
          storePriceLevel: PRICE_LEVEL,
          scheduledDay: 0,
          onDemandTerminalId: kitchen.displayOptions.onDemandTerminalId,
          orderTimeZone: kitchen.timeZone,
          useIgOrderApi: kitchen.useIgOrderApi,
          properties: _add_cart_new.Properties3(
              checkTypeId: kitchen.displayOptions.checkType,
              employeeId: kitchen.displayOptions.onDemandEmployeeId,
              profitCenterId: kitchen.displayOptions.profitCenterId,
              orderSourceSystem: 'onDemand',
              orderNumberSequenceLength: 4,
              orderNumberNameSpace: kitchen.displayOptions.onDemandTerminalId,
              voidReasonId: kitchen.displayOptions.voidReasonId
          ),
        scheduledOrderCompletionTimeStamp: DateTime.now().toIso8601StringNoMs()
      ), contextId: config.contextID)
          .then((value) => value.orderDetails);
    }

    return onDemand.addCart(_add_cart.Request(
        item: item,
        currencyDetails: currencyDetails,
        schedule: null,
        scheduleTime: orderPlaceTime.toScheduleTime(),
        storePriceLevel: PRICE_LEVEL,
        scheduledDay: 0,
    ), contextId: config.contextID, orderId: _orderId)
      .then((_) => null);
  }
}
