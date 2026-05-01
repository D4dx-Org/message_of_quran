import 'package:flutter/material.dart';

class HomeScreenSliverAppbar extends StatelessWidget {
  const HomeScreenSliverAppbar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      surfaceTintColor: theme.scaffoldBackgroundColor,
      backgroundColor: theme.scaffoldBackgroundColor,
    );
  }
}
