// GENERATED CODE - DO NOT MODIFY BY HAND
import './app_localizations.dart';

String resolveL10n(
  AppLocalizations l10n,
  String key,
  Map<String, dynamic>? args,
) {
  switch (key) {
    case 'common_global_body_gender_label':
      return l10n.common_global_body_gender_label((args?['gender'] as String));
    case 'common_global_body_apple_label':
      return l10n.common_global_body_apple_label((args?['count'] as num));
    case 'common_global_body_assembleWhoseApple_label':
      return l10n.common_global_body_assembleWhoseApple_label(
        args?['whose'] ?? '',
        args?['apple'] ?? '',
      );
    case 'common_global_action_confirm_exit_label':
      return l10n.common_global_action_confirm_exit_label;
    case 'home_index_header_welcome_label':
      return l10n.home_index_header_welcome_label(args?['username'] ?? '');
    case 'home_index_header_default_title':
      return l10n.home_index_header_default_title;
    case 'home_index_counter_increment_label':
      return l10n.home_index_counter_increment_label;
    case 'home_index_counter_increment_action':
      return l10n.home_index_counter_increment_action;
    default:
      throw Exception('Key $key not found in AppLocalizations');
  }
}
