// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String common_global_body_gender_label(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': 'He',
      'female': 'She',
      'other': 'They',
    });
    return '$_temp0';
  }

  @override
  String common_global_body_apple_label(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'has $count apples',
      one: 'has one apple',
    );
    return '$_temp0';
  }

  @override
  String common_global_body_assembleWhoseApple_label(
    Object whose,
    Object apple,
  ) {
    return '$whose $apple';
  }

  @override
  String get common_global_action_confirm_exit_label => 'Are you sure to exit?';

  @override
  String home_index_header_welcome_label(Object username) {
    return 'Welcome, $username!';
  }

  @override
  String get home_index_header_default_title => 'Multi Language Home Page';

  @override
  String get home_index_counter_increment_label =>
      'You have pushed the button this many times:';

  @override
  String get home_index_counter_increment_action => 'Increment';
}
