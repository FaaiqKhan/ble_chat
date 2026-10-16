import 'package:flutter/widgets.dart';

/// Screen-level paddings shared across the app, so the same layout role uses
/// the same inset everywhere. Change a value here to change it app-wide.
abstract final class AppPadding {
  /// Top bar (back button, title, trailing action) in portrait.
  static const portraitTopBar = EdgeInsets.fromLTRB(8, 6, 8, 4);

  /// Body of a portrait screen.
  static const portraitScreen = EdgeInsets.fromLTRB(18, 8, 18, 18);

  /// Body of a portrait screen whose content scrolls under the bottom edge
  /// (no bottom inset, so the scroll view isn't cut short).
  static const portraitScrollScreen = EdgeInsets.fromLTRB(18, 8, 18, 0);
}
