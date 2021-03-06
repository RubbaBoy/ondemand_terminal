import 'package:dart_console/dart_console.dart';
import 'package:ondemand_terminal/extensions.dart';

class Breadcrumb {
  final Console console;

  final Coordinate position;

  /// Resets the position to this after updates
  final Coordinate resetPosition;

  final ConsoleColor textColor;

  final ConsoleColor arrowColor;

  final List<String> trail;

  Breadcrumb(
      {this.console,
        this.position,
        this.resetPosition,
        this.textColor = ConsoleColor.brightGreen,
        this.arrowColor = ConsoleColor.brightRed,
        this.trail});

  void update() {
    console.cursorPosition = position;
    console.eraseLine();

    trail.forEachI((i, item) {
      if (i != 0) {
        console.setForegroundColor(arrowColor);
        console.write(' > ');
      }
      console.setForegroundColor(textColor);
      console.write(item);
    });

    console.resetColorAttributes();
    console.cursorPosition = resetPosition;
  }

  void trailAdd(String item) {
    trail.add(item);
    update();
  }

  void trailPop([int count = 1]) {
    for (;count > 0; count--) {
      trail.removeLast();
    }
    update();
  }
}