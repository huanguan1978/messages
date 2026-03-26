// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String common_global_body_gender_label(String gender) {
    String _temp0 = intl.Intl.selectLogic(gender, {
      'male': '他',
      'female': '她',
      'other': '它',
    });
    return '$_temp0';
  }

  @override
  String common_global_body_apple_label(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 个苹果',
      one: '有 1 个苹果',
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
  String get common_global_action_confirm_exit_label => '你确定要退出吗?';

  @override
  String home_index_header_welcome_label(Object username) {
    return '欢迎:, $username!';
  }

  @override
  String get home_index_header_default_title => '多语言首页';

  @override
  String get home_index_counter_increment_label => '你已按下按钮次数:';

  @override
  String get home_index_counter_increment_action => '递增';
}
