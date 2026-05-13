import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/widgets/settings_screen_card.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class SearchScreen extends StatelessWidget {
  const SearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Provider.of<SurahProvider>(context, listen: false);
    return BaseScreenLayout(
      appBar: AppBar(
        title: Text("Search", style: AppTextTheme.titleRegular.copyWith(color: Colors.white)),
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
      child: Padding(
          padding: const EdgeInsets.fromLTRB(10.0, 20.0, 10.0, 10.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: SearchBar(
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
                      hintText: "Search By Surah ",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Consumer<SurahProvider>(
                builder: (context, value, child) {
                  return Expanded(
                    child: controller.searchList.isEmpty
                        ? Center(
                            child: Text(
                              controller.isSearched
                                  ? "No data"
                                  : "Search To See Surah",
                            ),
                          )
                        : ListView.separated(
                            itemBuilder: (context, index) => InkWell(
                              onTap: () {
                                final surah = controller.searchList[index];
                                final idx = controller.surahList.indexWhere(
                                  (s) => s.surahNumber == surah.surahNumber,
                                );
                                if (idx < 0) return;
                                controller.assignIndex(idx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const SurahScreen(),
                                  ),
                                );
                              },
                              child: SettingsScreenCard(
                                child: ListTile(
                                  tileColor: Colors.transparent,
                                  title: Text(
                                    controller.searchList[index].name,
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
              ),
            ],
          ),
        ),
    );
  }
}
