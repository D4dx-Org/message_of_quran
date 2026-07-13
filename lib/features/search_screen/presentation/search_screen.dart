import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/utils/responsive_helper.dart';
import 'package:the_message_of_the_quran/core/utils/surah_name_localizer.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/link_hover/hover_link.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  bool _useDesktopWebLayout(BuildContext context) {
    return kIsWeb;
  }

  Widget _buildSearchField(BuildContext context, SurahProvider controller) {
    return SearchBar(
      trailing: [
        IconButton(
          onPressed: () {
            controller.clear();
          },
          icon: const Icon(Icons.close),
        ),
      ],
      onChanged: (value) => controller.search(),
      controller: controller.searchController,
      hintText: 'Search By Surah ',
    );
  }

  void _openSearchResult(
    BuildContext context,
    SurahProvider controller,
    int index,
  ) {
    final surah = controller.searchList[index];
    context.push('/surah/${surah.surahNumber}');
  }

  Widget _buildMobileResults(BuildContext context, SurahProvider controller) {
    return Consumer<SurahProvider>(
      builder: (context, value, child) {
        return Expanded(
          child: controller.searchList.isEmpty
              ? Center(
                  child: Text(
                    controller.isSearched ? 'No data' : 'Search To See Surah',
                  ),
                )
              : ListView.separated(
                  itemBuilder: (context, index) => HoverLink(
                    url: '/surah/${controller.searchList[index].surahNumber}',
                    child: InkWell(
                    onTap: () => _openSearchResult(context, controller, index),
                    child: SettingsScreenCard(
                      child: ListTile(
                        tileColor: Colors.transparent,
                        title: Text(controller.searchList[index].name),
                      ),
                    ),
                    ),
                  ),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 10),
                  itemCount: controller.searchList.length,
                ),
        );
      },
    );
  }

  Widget _buildDesktopResults(BuildContext context, SurahProvider controller) {
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final primaryTextColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    final secondaryTextColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey[600]!;

    return Consumer<SurahProvider>(
      builder: (context, value, child) {
        if (controller.searchList.isEmpty) {
          return Center(
            child: Text(
              controller.isSearched
                  ? 'No surah matched your search.'
                  : 'Type a surah name to start searching.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          );
        }

        return ListView.separated(
          itemCount: controller.searchList.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final surah = controller.searchList[index];
            final displayText = formatSurahListDisplayText(
              isMalayalam: isMalayalam,
              surahName: surah.name,
              surahTranslation: surah.description,
              malayalamName: surah.malayalamName,
              surahNumber: surah.surahNumber,
            );

            return HoverLink(
              url: '/surah/${surah.surahNumber}',
              child: InkWell(
              onTap: () => _openSearchResult(context, controller, index),
              borderRadius: BorderRadius.circular(16),
              child: SettingsScreenCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayText.title,
                              style: AppTextTheme.localizedLabel(
                                isMalayalam: isMalayalam,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: primaryTextColor,
                              ),
                            ),
                            if (displayText.subtitle.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                displayText.subtitle,
                                style: AppTextTheme.localizedBody(
                                  isMalayalam: isMalayalam,
                                  fontSize: 13,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        surah.arabicName,
                        textAlign: TextAlign.right,
                        style: AppTextTheme.localizedLabel(
                          isMalayalam: false,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopBody(BuildContext context, SurahProvider controller) {
    final hPad = ResponsiveHelper.horizontalPadding(context);
    final isMalayalam = context.watch<LanguageProvider>().isMalayalam;
    final primaryTextColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white
        : Theme.of(context).colorScheme.primary;
    final secondaryTextColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.white70
        : Colors.grey[600]!;

    return Padding(
      padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Image.asset(
                'assets/images/symbol-logo.png',
                height: 84,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
              const SizedBox(height: 18),
              Text(
                isMalayalam ? 'തിരയുക' : 'Search the Qur\'an',
                textAlign: TextAlign.center,
                style: AppTextTheme.localizedTitle(
                  isMalayalam: isMalayalam,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isMalayalam
                    ? 'സൂറത്ത്, പരിഭാഷ, അല്ലെങ്കിൽ റഫറൻസ് തിരഞ്ഞ് നേരിട്ട് തുറക്കാം.'
                    : 'Find a surah quickly and open it directly from the results.',
                textAlign: TextAlign.center,
                style: AppTextTheme.localizedBody(
                  isMalayalam: isMalayalam,
                  fontSize: 14,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 20),
              SettingsScreenCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildSearchField(context, controller),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<SurahProvider>(
                builder: (context, value, child) {
                  return Row(
                    children: [
                      Text(
                        isMalayalam ? 'റിസൾട്ടുകൾ' : 'Results',
                        style: AppTextTheme.localizedLabel(
                          isMalayalam: isMalayalam,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: primaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${value.searchList.length} ${isMalayalam ? 'സൂറത്ത്' : 'surahs'}',
                        style: AppTextTheme.localizedBody(
                          isMalayalam: isMalayalam,
                          fontSize: 13,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SettingsScreenCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _buildDesktopResults(context, controller),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SurahProvider>(context, listen: false);
    final useDesktopWebLayout = _useDesktopWebLayout(context);

    return BaseScreenLayout(
      appBar: AppBar(
        title: Text(
          'Search',
          style: AppTextTheme.titleRegular.copyWith(
            color: appBarTitleMatchedAccentColor(context),
          ),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          alignment: Alignment.center,
          icon: const Icon(
            Icons.arrow_back_ios_new_outlined,
            color: Colors.white,
          ),
        ),
      ),
      child: useDesktopWebLayout
          ? _buildDesktopBody(context, controller)
          : Padding(
              padding: const EdgeInsets.fromLTRB(10.0, 0, 10.0, 10.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildSearchField(context, controller)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildMobileResults(context, controller),
                ],
              ),
            ),
    );
  }
}
