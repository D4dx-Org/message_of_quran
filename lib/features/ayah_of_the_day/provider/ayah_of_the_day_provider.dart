import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_message_of_the_quran/features/ayah_of_the_day/data/ayah_of_the_day_model.dart';
import 'package:the_message_of_the_quran/features/ayah_of_the_day/services/ayah_of_the_day_service.dart';

class AyahOfTheDayProvider extends ChangeNotifier {
  AyahOfTheDayModel? _todaysAyah;
  bool _isLoading = false;
  String? _error;
  bool _isSharing = false;

  AyahOfTheDayModel? get todaysAyah => _todaysAyah;
  bool get isLoading => _isLoading;
  bool get isSharing => _isSharing;
  String? get error => _error;

  Future<void> loadTodaysAyah() async {
    if (_isLoading) return;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _todaysAyah = await AyahOfTheDayService.getTodaysAyah();
    } catch (e) {
      _error = e.toString();
      debugPrint('AyahOfTheDayProvider: load error – $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Captures the poster widget via its [RepaintBoundary] key, saves as a
  /// high-res PNG, and opens the system share sheet.
  Future<void> shareAsPoster(GlobalKey repaintKey) async {
    if (_isSharing) return;
    _isSharing = true;
    notifyListeners();

    try {
      // Wait for any pending frame to finish rendering.
      await Future.delayed(const Duration(milliseconds: 100));
      final completer = Completer<void>();
      SchedulerBinding.instance.addPostFrameCallback((_) => completer.complete());
      await completer.future;

      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return;

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/ayah_of_the_day.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Ayah of the Day',
        text: '${_todaysAyah?.surahNameArabic ?? ''} – Ayah ${_todaysAyah?.ayahNo ?? ''}',
      );
    } catch (e) {
      debugPrint('AyahOfTheDayProvider: share error – $e');
    } finally {
      _isSharing = false;
      notifyListeners();
    }
  }

  /// Shares the ayah as plain text (Arabic + translation + surah reference).
  Future<void> shareAsText() async {
    if (_todaysAyah == null) return;
    final a = _todaysAyah!;
    final text = '${a.arabicText}\n\n'
        '${a.translationText}\n\n'
        '— ${a.surahNameArabic} | Ayah ${a.ayahNo}';
    await Share.share(text, subject: 'Ayah of the Day');
  }
}
