import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/services/database/database_ready_notifier.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_list_row_text_styles.dart';
import 'package:the_message_of_the_quran/features/home_screen/presentation/widgets/home_screen_list_tile.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/last_read_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class HomeScreenList extends StatelessWidget {
  /// Optional controller wired to the main surah ListView.
  final ScrollController? scrollController;

  const HomeScreenList({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    final hPad = ResponsiveHelper.horizontalPadding(context);
    final dbStatus = context.watch<DatabaseReadyNotifier>().status;
    return Consumer<SurahProvider>(
      builder: (context, surahProvider, child) {
        if (surahProvider.isSurahLoading ||
            (dbStatus == DbInitStatus.loading &&
                surahProvider.surahList.isEmpty)) {
          return const Center(
            child: CircularProgressIndicator(
              color: AppTheme.appIconTheme,
            ),
          );
        }
        if (dbStatus == DbInitStatus.failed &&
            surahProvider.surahList.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not load Surahs.'),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      context.read<DatabaseReadyNotifier>().retry(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }
        if (surahProvider.surahList.isEmpty) {
          return const Center(child: Text('No Surahs available'));
        }
        return ListView.builder(
          controller: scrollController,
          padding: EdgeInsets.fromLTRB(hPad, homeListTopPadding, hPad, 0),
          itemCount: surahProvider.surahList.length,
          itemBuilder: (context, index) {
            return HomeScreenListTile(
              index: index,
              onTap: () async {
                final surahNumber = surahProvider.surahList[index].surahNumber;
                await context.push('/surah/$surahNumber');
                if (!context.mounted) return;
                // Use the surah the provider is currently on, so a jump to a
                // different surah inside the SurahScreen is reflected here
                // instead of the originally tapped surah.
                final currentIndex = surahProvider.index;
                if (currentIndex >= 0 &&
                    currentIndex < surahProvider.surahList.length) {
                  context.read<LastReadProvider>().saveLastSurahTabSelection(
                        surahProvider.surahList[currentIndex].surahNumber,
                      );
                }
              },
            );
          },
        );
      },
    );
  }
}

