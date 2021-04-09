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
