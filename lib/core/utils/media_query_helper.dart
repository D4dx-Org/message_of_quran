import 'package:flutter/material.dart';

class MediaQueryHelper {
  MediaQueryHelper._();
  static double toGetHeight(BuildContext ctx) {
    return MediaQuery.of(ctx).size.height;
  }

  static double toGetWidth(BuildContext ctx) {
    return MediaQuery.of(ctx).size.width;
  }

  static bool isPotrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  static double toGetSafeAreaSize(BuildContext context) {
    return MediaQuery.of(context).viewPadding.top +
        MediaQuery.of(context).viewPadding.bottom;
  }

  static double toGetNotchSize(BuildContext context) {
    return MediaQuery.of(context).viewPadding.top;
  }
}
