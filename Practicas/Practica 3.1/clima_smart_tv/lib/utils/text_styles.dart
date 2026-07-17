import 'package:flutter/material.dart';

import '../config/app_theme.dart';
import 'tv_constants.dart';

class TVTextStyles {
  static const city = TextStyle(
    fontSize: TVConstants.city,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const temperature = TextStyle(
    fontSize: TVConstants.temperature,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );

  static const condition = TextStyle(
    fontSize: TVConstants.condition,
    color: Colors.white,
  );

  static const details = TextStyle(
    fontSize: TVConstants.details,
    color: AppTheme.detailColor,
  );

  static const header = TextStyle(
    fontSize: TVConstants.header,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}