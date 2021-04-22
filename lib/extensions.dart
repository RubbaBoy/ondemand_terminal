import 'dart:io';

extension ListUtility<E> on Iterable<E> {
  void forEachI(void Function(int index, E element) action) {
    var i = 0;
    forEach((e) => action(i++, e));
  }

  E safeReduce(E Function(E value, E element) combine) =>
      isEmpty ? null : reduce(combine);
}

extension StringUtils on String {
  int parseInt() => int.tryParse(this);

  double parseDouble() => double.parse(this);

  File get file => File(this);

  Directory get directory => Directory(this);

  Uri get uri => Uri.tryParse(this);
}

extension SpecialIso on DateTime {
  String toIso8601StringNoMs() {
    var y = (year >= -9999 && year <= 9999) ? _fourDigits(year) : _sixDigits(year);
    var m = _twoDigits(month);
    var d = _twoDigits(day);
    var h = _twoDigits(hour);
    var min = _twoDigits(minute);
    var sec = _twoDigits(second);
    return '$y-$m-${d}T$h:$min:${sec}Z';
  }

  static String _fourDigits(int n) {
    var absN = n.abs();
    var sign = n < 0 ? '-' : '';
    if (absN >= 1000) return '$n';
    if (absN >= 100) return '${sign}0$absN';
    if (absN >= 10) return '${sign}00$absN';
    return '${sign}000$absN';
  }

  static String _sixDigits(int n) {
    assert(n < -9999 || n > 9999);
    var absN = n.abs();
    var sign = n < 0 ? '-' : '+';
    if (absN >= 100000) return '$sign$absN';
    return '${sign}0$absN';
  }

  static String _twoDigits(int n) {
    if (n >= 10) return '$n';
    return '0$n';
  }
}
