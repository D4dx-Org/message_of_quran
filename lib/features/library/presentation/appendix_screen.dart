import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:the_message_of_the_quran/core/models/appendix_model.dart';
import 'package:the_message_of_the_quran/core/services/database/appendix_db_helper.dart';
import 'package:the_message_of_the_quran/core/services/database/database_ready_notifier.dart';
import 'package:the_message_of_the_quran/core/theme/app_text_theme.dart';
import 'package:the_message_of_the_quran/core/theme/app_theme.dart';
import 'package:the_message_of_the_quran/core/theme/theme_provider.dart';
import 'package:the_message_of_the_quran/core/widgets/base_screen_layout.dart';
import 'package:the_message_of_the_quran/core/widgets/common_app_bar.dart';
import 'package:the_message_of_the_quran/core/widgets/common_drawer.dart';
import 'package:the_message_of_the_quran/features/main_screen/presentation/main_screen.dart';
import 'package:the_message_of_the_quran/features/main_screen/providers/home_provider.dart';
import 'package:the_message_of_the_quran/features/settings_screen/presentation/settings_screen.dart';
import 'package:the_message_of_the_quran/features/settings_screen/providers/language_provider.dart';

class AppendixScreen extends StatefulWidget {
  const AppendixScreen({super.key, this.initialAppendixNumber});

  /// When provided, the matching appendix is auto-expanded and scrolled into
  /// view once the list has loaded.
  final int? initialAppendixNumber;

  @override
  State<AppendixScreen> createState() => _AppendixScreenState();
}

class _AppendixScreenState extends State<AppendixScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _cardKeys = {};
  final Map<int, GlobalKey> _titleKeys = {};
  List<AppendixModel> _allAppendices = [];
  List<AppendixModel> _filteredAppendices = [];
  bool _isLoading = true;
  int? _expandedIndex;
  bool? _loadedMalayalam;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isMalayalam = Provider.of<LanguageProvider>(context).isMalayalam;
    if (_loadedMalayalam == isMalayalam) return;

    _loadedMalayalam = isMalayalam;
    _loadAppendices(isMalayalam);
  }

  Future<void> _loadAppendices(bool isMalayalam) async {
    setState(() {
      _isLoading = true;
      _expandedIndex = null;
    });

    // On web the DB loads in the background after first paint; querying
    // before it's ready silently yields an empty list.
    final dbNotifier = context.read<DatabaseReadyNotifier>();
    if (dbNotifier.status != DbInitStatus.ready) {
      await dbNotifier.whenReady;
    }
    if (!mounted) return;

    final data = await AppendixDbHelper.getAppendices(
      malayalam: isMalayalam,
    );
    if (!mounted) return;
    setState(() {
      _allAppendices = data;
      _filteredAppendices = data;
      _isLoading = false;
    });
    _openInitialAppendix();
  }

  void _openInitialAppendix() {
    final target = widget.initialAppendixNumber;
    if (target == null) return;
    final index =
        _filteredAppendices.indexWhere((a) => a.number == target);
    if (index < 0) return;
    _onCardTapped(index);
  }

  void _onSearchChanged(String query) {
    setState(() {
      _expandedIndex = null;
      if (query.isEmpty) {
        _filteredAppendices = _allAppendices;
      } else {
        _filteredAppendices = _allAppendices
            .where((a) => a.title.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  void _onCardTapped(int index) {
    setState(() {
      if (_expandedIndex == index) {
        _expandedIndex = null;
      } else {
        _expandedIndex = index;
      }
    });

    if (_expandedIndex == index) {
      // Scroll after layout is ready — no fixed delay needed
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final key = _cardKeys[index];
        if (key?.currentContext != null) {
          Scrollable.ensureVisible(
            key!.currentContext!,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            alignment: 0.0,
            alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
          );
        }
      });
    }
  }
 
  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).brightness == Brightness.dark
        ? appBarTitleMatchedAccentColor(context)
        : AppTheme.appThemePrimary;
    final isMalayalam = Provider.of<LanguageProvider>(context).isMalayalam;

    return BaseScreenLayout(
      appBar:  CommonAppBar.homeAppBar(
          context,
          showOrnament: false,
          title:isMalayalam?"അനുബന്ധം": "Appendix"
        ),
        drawer: const CommonDrawer(),
      child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search appendix...',
                      hintStyle: AppTextTheme.popinsDefault(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Colors.grey.shade400,
                      ),
                      filled: true,
                      fillColor:
                          Theme.of(context).brightness == Brightness.dark
                              ? const Color(0xff163d6e)
                              : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                // List
                Expanded(
                  child: _filteredAppendices.isEmpty
                      ? const Center(
                          child: Text(
                            'No appendices found.',
                            style:
                                TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: _filteredAppendices.length,
                          itemBuilder: (context, index) {
                            _cardKeys.putIfAbsent(
                                index, () => GlobalKey());
                            _titleKeys.putIfAbsent(
                                index, () => GlobalKey());
                            final appendix = _filteredAppendices[index];
                            return _AppendixAccordionTile(
                              key: _cardKeys[index],
                              titleKey: _titleKeys[index]!,
                              appendix: appendix,
                              accentColor: accentColor,
                              isMalayalam: isMalayalam,
                              isExpanded: _expandedIndex == index,
                              onTap: () => _onCardTapped(index),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

class _AppendixAccordionTile extends StatelessWidget {
  const _AppendixAccordionTile({
    super.key,
    required this.titleKey,
    required this.appendix,
    required this.accentColor,
    required this.isMalayalam,
    required this.isExpanded,
    required this.onTap,
  });

  final GlobalKey titleKey;
  final AppendixModel appendix;
  final Color accentColor;
  final bool isMalayalam;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xff163d6e) : Colors.white;
    final numeral = appendix.romanNumeral.isEmpty
        ? appendix.number.toString()
        : appendix.romanNumeral.toUpperCase();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        shadowColor: Colors.black12,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xff1a4a82) : Colors.grey.shade200,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  key: titleKey,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text(
                        numeral,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        appendix.title.toUpperCase(),
                        style: AppTextTheme.localizedLabel(
                          isMalayalam: isMalayalam,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          color: accentColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: AnimatedRotation(
                        turns: isExpanded ? 0.50 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Icon(
                          Icons.expand_more,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                // Expandable body content — instant show/hide
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      appendix.body,
                      style: AppTextTheme.localizedBody(
                        isMalayalam: isMalayalam,
                        fontSize: 15,
                        height: 1.7,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
