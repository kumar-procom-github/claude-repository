import 'package:flutter/material.dart';

/// The app's own language (the screens before the details form).
/// Card wording is separate: the details form stays bilingual.
enum AppLang { en, te }

class AppLangController {
  AppLangController._();

  /// English by default; the user's choice is saved in UserPrefs.
  static final lang = ValueNotifier<AppLang>(AppLang.en);
}

/// Rebuilds every screen that reads the language when it changes.
class LangScope extends InheritedNotifier<ValueNotifier<AppLang>> {
  const LangScope({super.key, required super.notifier, required super.child});

  static AppLang of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<LangScope>()?.notifier?.value ?? AppLangController.lang.value;

  static bool isTe(BuildContext context) => of(context) == AppLang.te;
}

/// Pick the text for the current app language.
extension Tr on BuildContext {
  String tr(String en, String te) => LangScope.isTe(this) ? te : en;
}
