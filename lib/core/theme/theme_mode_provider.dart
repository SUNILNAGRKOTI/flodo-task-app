import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';

/// Theme toggle state. Defaults to system; UI can override to light/dark.
final themeModeProvider = StateProvider<ThemeMode>(
  (ref) => ThemeMode.system,
);

