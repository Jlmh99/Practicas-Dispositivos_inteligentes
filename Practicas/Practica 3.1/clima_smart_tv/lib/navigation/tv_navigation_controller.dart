import 'package:flutter/material.dart';

class TVNavigationController extends ChangeNotifier {
  int _focusedIndex = 0;

  int get focusedIndex => _focusedIndex;

  void moveUp() {
    switch (_focusedIndex) {
      case 2:
        _focusedIndex = 0;
        break;
      case 3:
        _focusedIndex = 1;
        break;
    }
    notifyListeners();
  }

  void moveDown() {
    switch (_focusedIndex) {
      case 0:
        _focusedIndex = 2;
        break;
      case 1:
        _focusedIndex = 3;
        break;
    }
    notifyListeners();
  }

  void moveLeft() {
    switch (_focusedIndex) {
      case 1:
        _focusedIndex = 0;
        break;
      case 3:
        _focusedIndex = 2;
        break;
    }
    notifyListeners();
  }

  void moveRight() {
    switch (_focusedIndex) {
      case 0:
        _focusedIndex = 1;
        break;
      case 2:
        _focusedIndex = 3;
        break;
    }
    notifyListeners();
  }

  void select() {
    debugPrint("Tarjeta seleccionada: $_focusedIndex");
  }
}