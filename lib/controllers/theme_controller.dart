import 'package:flutter/material.dart';

class ThemeController extends ChangeNotifier {
  bool _modoEscuro = false;

  bool get modoEscuro => _modoEscuro;
  ThemeMode get themeMode =>
      _modoEscuro ? ThemeMode.dark : ThemeMode.light;

  void toggle() {
    _modoEscuro = !_modoEscuro;
    notifyListeners();
  }
}