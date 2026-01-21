import 'package:flutter/foundation.dart';

/// Global scroll lock manager for writing pages
/// When true, prevents page scrolling to avoid conflicts with stylus writing
class ScrollLockManager {
  final ValueNotifier<bool> isScrollLocked = ValueNotifier(false);
}

final scrollLockManager = ScrollLockManager();