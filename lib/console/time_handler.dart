import 'package:ondemand_terminal/extensions.dart';

List<OrderTime> calculateOrderTimes(Time startTime, Time endTime, int intervalTime, int bufferTime) {
  var times = <OrderTime>[];
  while (isAfter(startTime, endTime)) {
    var newStartTime = startTime.add(minute: intervalTime);
    times.add(OrderTime(startTime, newStartTime));
    startTime = newStartTime;
  }

  var now = Time.fromDateTime(DateTime.now().add(Duration(minutes: bufferTime)));
  while (times.isNotEmpty && isAfter(times.first.start, now)) {
    times.removeAt(0);
  }

  if (times.isEmpty) {
    // TODO: This is a hack! Make this in env variables!!!
    times.add(OrderTime(Time.fromString('7:15 pm'), Time.fromString('7:30 pm')));
  }

  return times;
}

/// Checks if the time b is after a.
/// Time examples: `7:30 pm`, `12:45 am`
/// If [inclusive] is [true] and the times are equal, [true] is returned.
bool isAfter(Time a, Time b, [bool inclusive = false]) {
  if (a == b) {
    return inclusive;
  }

  var aHour = a.hour;
  var bHour = b.hour;
  if (a.amPm == 'pm') {
    aHour = a.hour + 12;
  }

  if (b.amPm == 'pm') {
    bHour = b.hour + 12;
  }

  if (bHour > aHour) {
    return true;
  } else if (bHour < aHour) {
    return false;
  }

  return b.minute > a.minute;
}

/// Checks if the given [time] is between the timespan of [orderTime],
/// inclusively.
bool isBetweenOrderTime(Time time, OrderTime orderTime) =>
    isBetween(time, orderTime.start, orderTime.end);

/// Checks if the given [time] is between the times of [a] and [b], inclusively.
bool isBetween(Time time, Time a, Time b) =>
    isAfter(a, time, true) && isAfter(time, b, true);

/// And order time (time should be in increments of 15 minutes)
class OrderTime {
  final Time start;
  final Time end;

  const OrderTime(this.start, this.end);

  factory OrderTime.fromAvailableAt(dynamic availableAt) =>
      OrderTime(Time.fromString(availableAt.opens), Time.fromString(availableAt.closes));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrderTime &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  String toString() => '$start - $end';
}

class Time {
  final int hour;
  final int minute;
  final String amPm;

  Time(this.hour, this.minute, this.amPm);

  factory Time.fromString(String time) {
    var split = time.split(RegExp(r'[\s:]'));
    // TODO: Yucky!
    if (split.length != 3) {
      return Time.fromString('12:00 am');
    }
    return Time(split[0].parseInt(), split[1].parseInt(), split[2]);
  }

  factory Time.now() => Time.fromDateTime(DateTime.now());

  Time.fromDateTime(DateTime dateTime)
      : hour = (dateTime.hour % 12),
        minute = dateTime.minute,
        amPm = dateTime.hour > 12 ? 'pm' : 'am';

  Time copy({int hour, int minute, String amPm}) =>
      Time(hour ?? this.hour, minute ?? this.minute, amPm ?? this.amPm);

  Time add({int hour = 0, int minute = 0}) {
    var newHour = this.hour + hour;
    var newMinute = this.minute + minute;
    var newAmPm = amPm;

    newHour += (newMinute / 60).floor();
    newMinute %= 60;

    var excessHour = (newHour / 12).floor();
    newHour %= 12;

    if (excessHour % 2 != 0) {
      newAmPm = amPm == 'am' ? 'pm' : 'am';
    }

    return Time(newHour, newMinute, newAmPm);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Time &&
              runtimeType == other.runtimeType &&
              hour == other.hour &&
              minute == other.minute &&
              amPm == other.amPm;

  @override
  int get hashCode => hour.hashCode ^ minute.hashCode ^ amPm.hashCode;

  @override
  String toString() {
    var printHour = hour;
    if (hour == 0) {
      printHour = 12;
    }
    return '$printHour:${minute.toString().padLeft(2, '0')} $amPm';
  }
}