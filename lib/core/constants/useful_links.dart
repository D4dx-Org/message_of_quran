class UsefulLinkItem {
  const UsefulLinkItem({
    required this.title,
    required this.url,
  });

  final String title;
  final String url;
}

class UsefulLinkSection {
  const UsefulLinkSection({
    required this.title,
    required this.links,
  });

  final String title;
  final List<UsefulLinkItem> links;
}

/// External resources shown under the drawer "Useful Links" section.
/// Add new sections or links here as needed.
const List<UsefulLinkSection> usefulLinksSections = [
  UsefulLinkSection(
    title: "Al Qur'an Translations",
    links: [
      UsefulLinkItem(
        title: 'Abdullah Yusuf Ali',
        url: 'https://www.alim.org/translation/yusuf-ali/1/',
      ),
      UsefulLinkItem(
        title: 'Muhammad Marmaduke Pickthall',
        url: 'https://www.alim.org/translation/picktal/1/',
      ),
    ],
  ),
  UsefulLinkSection(
    title: 'Hadith Collection',
    links: [
      UsefulLinkItem(
        title: 'Sahih Al Bukhari',
        url: 'https://www.alim.org/hadith/sahih-bukhari/landing/',
      ),
      UsefulLinkItem(
        title: 'Sahih Muslim',
        url: 'https://www.alim.org/hadith/sahih-muslim/landing/',
      ),
      UsefulLinkItem(
        title: 'Tirmidhi',
        url: 'https://www.alim.org/hadith/tirmidi/landing/',
      ),
      UsefulLinkItem(
        title: 'Abu Dawud',
        url: 'https://www.alim.org/hadith/sunan-of-abu-dawood/landing/',
      ),
      UsefulLinkItem(
        title: 'Sunan an Nasai',
        url: 'https://www.alim.org/hadith/sunan-an-nasai/landing/',
      ),
      UsefulLinkItem(
        title: 'Sunan Ibn Majah',
        url: 'https://www.alim.org/hadith/sunan-ibn-majah/landing/',
      ),
      UsefulLinkItem(
        title: 'Nawawi',
        url: 'https://www.alim.org/hadith/nawawi/1/',
      ),
      UsefulLinkItem(
        title: 'Muwatta by Malik',
        url: 'https://www.alim.org/hadith/al-muwatta/landing/',
      ),
      UsefulLinkItem(
        title: 'Fiqh us-Sunnah by As-Sayyid Sabiq',
        url: 'https://www.alim.org/hadith/fiqh-us-sunnah/landing/',
      ),
    ],
  ),
  UsefulLinkSection(
    title: 'Quran Malayalam Translations',
    links: [
      UsefulLinkItem(
        title: "Thafheemul Qur'an by Maududi",
        url: 'https://thafheem.net/',
      ),
      UsefulLinkItem(
        title: 'Thafseer Amani',
        url: 'https://www.thafseeramani.com/index.asp',
      ),
    ],
  ),
];
