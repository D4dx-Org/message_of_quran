import 'package:the_message_of_the_quran/core/models/faq_category_model.dart';
import 'package:the_message_of_the_quran/core/models/help_model.dart';

class StaticFaqData {
  static List<FaqCategory> get faqCategories => [
        FaqCategory(
          categoryName: 'For Accessing Quran',
          items: [
            HelpModel(
              id: 'static_1',
              title: 'How do I navigate between Surahs?',
              description:
                  'You can browse all Surahs from the home screen. Tap on any Surah name to open it. Use the back button or swipe to return to the Surah list.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 1,
              isVerified: 1,
            ),
            HelpModel(
              id: 'static_2',
              title: 'How do I jump to a specific Ayah?',
              description:
                  'Open a Surah and tap on the Ayah number or use the search feature to find a specific Ayah by its number or text.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 2,
              isVerified: 1,
            ),
            HelpModel(
              id: 'static_3',
              title: 'How do I switch translations?',
              description:
                  'Go to Settings and select your preferred translation language. The app supports multiple translations that can be toggled on or off.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 3,
              isVerified: 1,
            ),
            HelpModel(
              id: 'static_4',
              title: 'What reading modes are available?',
              description:
                  "The app offers different reading modes including Mus'haf view and translation view. You can switch between them based on your preference.",
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 4,
              isVerified: 1,
            ),
          ],
        ),
        FaqCategory(
          categoryName: 'Audio Playback',
          items: [
            HelpModel(
              id: 'static_5',
              title: 'How do I play audio for a Surah or Ayah?',
              description:
                  'Tap the play button on any Surah or Ayah to start audio playback. The currently playing Ayah will be highlighted as it plays.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 1,
              isVerified: 1,
            ),
            HelpModel(
              id: 'static_6',
              title: 'How do I change the reciter?',
              description:
                  'Go to Settings and select your preferred reciter from the available list. The audio will use the selected reciter for all playback.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 2,
              isVerified: 1,
            ),
            HelpModel(
              id: 'static_7',
              title: 'Can I play audio continuously?',
              description:
                  'Yes, once you start playing audio it will continue to the next Ayah automatically. You can pause or stop playback at any time using the audio controls.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 3,
              isVerified: 1,
            ),
          ],
        ),
        FaqCategory(
          categoryName: 'Bookmarks & Notes',
          items: [
            HelpModel(
              id: 'static_8',
              title: 'How do I bookmark an Ayah?',
              description:
                  'Long press on any Ayah to open the options menu, then tap the bookmark icon. The Ayah will be saved to your bookmarks for quick access later.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 1,
              isVerified: 1,
            ),
            HelpModel(
              id: 'static_9',
              title: 'Where can I view my saved bookmarks?',
              description:
                  'You can access all your saved bookmarks from the bookmarks section in the app drawer or navigation menu.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 2,
              isVerified: 1,
            ),
            HelpModel(
              id: 'static_10',
              title: 'How do I remove a bookmark?',
              description:
                  'Go to your bookmarks list and swipe or tap the delete option on the bookmark you want to remove. You can also long press the Ayah again to toggle the bookmark off.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 3,
              isVerified: 1,
            ),
          ],
        ),
        FaqCategory(
          categoryName: 'App Settings & Theme',
          items: [
            HelpModel(
              id: 'static_11',
              title: 'How do I switch between dark and light mode?',
              description:
                  'Go to Settings and toggle the theme option to switch between dark and light mode. The app will remember your preference.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 1,
              isVerified: 1,
            ),
            HelpModel(
              id: 'static_12',
              title: 'Can I change the font size?',
              description:
                  'Yes, you can adjust the Arabic text and translation font sizes from the Settings screen. Use the slider to increase or decrease the size to your comfort.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 2,
              isVerified: 1,
            ),
            HelpModel(
              id: 'static_13',
              title: 'How do I change the app language?',
              description:
                  'Go to Settings and select your preferred language. The app interface will update to the selected language.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 3,
              isVerified: 1,
            ),
          ],
        ),
        FaqCategory(
          categoryName: 'Offline Usage',
          items: [
            HelpModel(
              id: 'static_14',
              title: 'Does the app work offline?',
              description:
                  'Yes, the Quran text and translations are stored locally on your device. You can read the Quran without an internet connection once the data has been downloaded.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 1,
              isVerified: 1,
            ),
            HelpModel(
              id: 'static_15',
              title: 'Is audio available offline?',
              description:
                  'Audio recitations require an internet connection for streaming. Make sure you have a stable connection for uninterrupted audio playback.',
              createdBy: 'system',
              createdByRole: 'admin',
              sortOrder: 2,
              isVerified: 1,
            ),
          ],
        ),
      ];
}
