import 'package:ondemand/base.dart';
import 'package:ondemand/get_config.dart' as _get_config;
import 'package:ondemand/get_items.dart' as _get_items;
import 'package:ondemand/login.dart' as _login;
import 'package:ondemand/get_kitchens.dart' as _get_kitchens;
import 'package:ondemand/get_manifest.dart' as _get_manifest;
import 'package:ondemand/decrypt_cookie.dart' as _decrypt_cookie;
import 'package:ondemand/get_leads.dart' as _get_leads;
import 'package:ondemand/list_places.dart' as _list_places;
import 'package:ondemand/get_menus.dart' as _get_menus;
import 'package:ondemand/get_item.dart' as _get_item;
import 'package:ondemand/add_cart_adv.dart' as _add_cart_adv;
import 'package:ondemand/add_cart.dart' as _add_cart;
import 'package:ondemand/account_inquiry.dart' as _account_inquiry;
import 'package:ondemand/get_revenue_category.dart' as _get_revenue_category;
import 'package:ondemand/get_tenders.dart' as _get_tenders;
import 'package:ondemand/get_tender_info.dart' as _get_tender_info;
import 'package:ondemand/auth_payment.dart' as _auth_payment;
import 'package:ondemand/check_capacity.dart' as _check_capacity;
import 'package:ondemand/create_closed_order.dart' as _create_closed_order;
import 'package:ondemand/get_sms.dart' as _get_sms;
import 'package:ondemand/send_sms.dart' as _send_sms;
import 'package:ondemand/get_wait_time.dart';
import 'package:ondemand/ondemand.dart';

import 'time_handler.dart';

class OnDemandLogic {
  OnDemand onDemand;
  _get_config.Response config;
  _get_kitchens.Response _kitchens;

  Future<void> init() async {
    var initialization = await Initialization.create();
    onDemand = initialization.onDemand;
    config = initialization.config;
  }

  Future<_get_kitchens.Response> _getKitchens() async =>
      _kitchens ??= await onDemand.getKitchens(_get_kitchens.Request());

  Future<List<OrderTime>> getOrderTimes() async {
    Time minTime;
    Time maxTime;
    for (var kitchen in (await _getKitchens()).kitchens) {
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
    return calculateOrderTimes(minTime, maxTime, scheduledOrdering.intervalTime, scheduledOrdering.bufferTime);
  }

  Future<List<_get_kitchens.Kitchen>> getKitchens() async =>
      (await _getKitchens()).kitchens;
}
