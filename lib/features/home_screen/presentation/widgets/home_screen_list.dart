import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class HomeScreenList extends StatelessWidget {
  /// Optional controller wired to the main surah ListView.
  final ScrollController? scrollController;

  const HomeScreenList({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final hPad = ResponsiveHelper.horizontalPadding(context);
    return Consumer<SurahProvider>(
      builder: (context, surahProvider, child) {
        if (surahProvider.isSurahLoading) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.appIconTheme,
            ),
          );
        }
        if (surahProvider.surahList.isEmpty) {
          return const Center(child: Text('No Surahs available'));
        }
        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 0),
          itemCount: surahProvider.surahList.length,
          itemBuilder: (context, index) {
            return HomeScreenListTile(
              index: index,
              onTap: () async {
                surahProvider.assignIndex(index);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SurahScreen(),
                  ),
                );
                if (!context.mounted) return;
                context.read<LastReadProvider>().saveLastSurahTabSelection(
                      surahProvider.surahList[index].surahNumber,
                    );
              },
            );
          },
        );
      },
    );
  }
}

