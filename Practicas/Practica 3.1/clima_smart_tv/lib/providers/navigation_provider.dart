import 'package:flutter_riverpod/legacy.dart';

import '../navigation/tv_navigation_controller.dart';

final navigationProvider =
    ChangeNotifierProvider<TVNavigationController>((ref) {
  return TVNavigationController();
});