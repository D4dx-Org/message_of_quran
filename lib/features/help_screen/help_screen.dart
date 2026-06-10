import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/features/help_screen/provider/help_provider.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<HelpProvider>(context, listen: false).getHelpInfo();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BaseScreenLayout(
      appBar: AppBar(
        title: Text('FAQ', style: AppTextTheme.titleRegular),
        centerTitle: false,
      ),
      child: Consumer<HelpProvider>(
        builder: (context, helpProvider, child) {
          if (helpProvider.isHelpLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (helpProvider.faqCategories.isEmpty) {
            return Center(
              child: Text(
                'No FAQ available',
                style: AppTextTheme.popinsDefault(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            itemCount: helpProvider.faqCategories.length,
            itemBuilder: (context, categoryIndex) {
              final category = helpProvider.faqCategories[categoryIndex];
              return ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 4,
                ),
                childrenPadding: const EdgeInsets.only(left: 16),
                collapsedShape: const BorderDirectional(
                  bottom: BorderSide(color: Colors.black12),
                ),
                shape: const BorderDirectional(
                  bottom: BorderSide(color: Colors.black),
                ),
                iconColor: AppTheme.appIconTheme,
                collapsedIconColor: AppTheme.appIconTheme,
                title: Text(
                  category.categoryName,
                  style: AppTextTheme.popinsDefault(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                children: category.items.map((item) {
                  return ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                      vertical: 4,
                      horizontal: 4,
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(4, 0, 4, 12),
                    collapsedShape: const BorderDirectional(
                      bottom: BorderSide(color: Colors.black12),
                    ),
                    shape: const BorderDirectional(
                      bottom: BorderSide(color: Colors.black12),
                    ),
                    iconColor: AppTheme.appIconTheme,
                    collapsedIconColor: AppTheme.appIconTheme,
                    title: Text(
                      item.title ?? 'Title Unavailable',
                      style: AppTextTheme.popinsDefault(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          item.description ?? 'Description Unavailable',
                          style: AppTextTheme.popinsDefault(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
