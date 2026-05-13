import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/juz_hizb_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/presentation/surah_screen.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class JuzColumn extends StatelessWidget {
  const JuzColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<JuzHizbProvider, SurahProvider>(
      builder: (context, provider, surahProvider, _) {
        if (provider.isLoading || provider.juzList.isEmpty) {
          return const SizedBox.shrink();
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: provider.juzList.length + 1,
          separatorBuilder: (_, _) => Divider(
            height: 1,
            color: Colors.grey.withValues(alpha: 0.2),
          ),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Container(
                height: 58.0 * MediaQuery.textScalerOf(context).scale(1),
                alignment: Alignment.center,
                child: Text(
                  '0',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.withValues(alpha: 0.4),
                  ),
                ),
              );
            }
            final juz = provider.juzList[index - 1];
            final available = surahProvider.surahList
                .any((s) => s.surahNumber == juz.surahNumber);
            return Semantics(
              button: available,
              label: 'Juz ${juz.number}',
              hint: available ? 'Double tap to open' : 'Not available',
              excludeSemantics: true,
              child: InkWell(
              onTap: available
                  ? () async {
                      final surahProv = context.read<SurahProvider>();
                      await surahProv.selectSurahByNumber(juz.surahNumber);
                      if (!context.mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              SurahScreen(scrollToAyahId: juz.ayahNumber),
                        ),
                      );
                    }
                  : null,
              child: Container(
                height: 58.0 * MediaQuery.textScalerOf(context).scale(1),
                alignment: Alignment.center,
                child: Text(
                  '${juz.number}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: available
                        ? Colors.black
                        : Colors.grey.withValues(alpha: 0.4),
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
}
