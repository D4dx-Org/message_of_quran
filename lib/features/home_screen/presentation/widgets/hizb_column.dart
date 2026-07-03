import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/juz_hizb_model.dart';
import 'package:the_message_of_the_quran/features/home_screen/providers/juz_hizb_provider.dart';
import 'package:the_message_of_the_quran/features/surah_screen/provider/surah_provider.dart';

class HizbColumn extends StatelessWidget {
  const HizbColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<JuzHizbProvider, SurahProvider>(
      builder: (context, provider, surahProvider, _) {
        if (provider.isLoading) {
          return const SizedBox.shrink();
        }

        return ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: 61,
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
            final hizbNumber = index;
            final hizb = provider.hizbList
                .cast<JuzHizbModel?>()
                .firstWhere((h) => h?.number == hizbNumber,
                    orElse: () => null);
            final available = hizb != null &&
                surahProvider.surahList
                    .any((s) => s.surahNumber == hizb.surahNumber);
            return Semantics(
              button: available,
              label: 'Hizb $hizbNumber',
              hint: available ? 'Double tap to open' : 'Not available',
              excludeSemantics: true,
              child: InkWell(
              onTap: available
                  ? () {
                      context.push(
                        '/surah/${hizb.surahNumber}?scrollToAyahId=${hizb.ayahNumber}',
                      );
                    }
                  : null,
              child: Container(
                height: 58.0 * MediaQuery.textScalerOf(context).scale(1),
                alignment: Alignment.center,
                child: Text(
                  '$hizbNumber',
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
