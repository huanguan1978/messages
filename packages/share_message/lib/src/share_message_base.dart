part of '../share_message.dart';

enum AppMessage implements MessageEnum {
  commonGlobalBodyGenderLabel(
    901,
    'common_global_body_gender_label',
    '{gender, select, male{He} female{She} other{They}}',
    'gobal gender (male | female) to (He | She).',
    param: {'gender': 'male'},
  ),
  commonGlobalBodyAppleLabel(
    902,
    'common_global_body_apple_label',
    '{count, plural, =1{has one apple} other{has {count} apples}}',
    '',
    param: {'count': 5},
  ),

  commonGlobalBodyAssembleWhoseAppleLabel(
    903,
    'common_global_body_assembleWhoseApple_label',
    '{whose} {apple}',
    'assemble whose apple.',
    param: {'whose': 'male', 'apple': 5},
  ),

  commonGlobalActionConfirmExitLabel(
    1001,
    'common_global_action_confirm_exit_label',
    'Are you sure to exit?',
    'cli exit tips.',
  ),
  homeIndexHeaderWelcomeLabel(
    1003,
    'home_index_header_welcome_label',
    'Welcome, {username}!',
    '',
    param: {'username': 'Guest'},
  ),
  homeIndexHeaderDefaultTitle(
    1004,
    'home_index_header_default_title',
    'Multi Language Home Page',
    '',
  ),
  homeIndexCounterIncrementLabel(
    1005,
    'home_index_counter_increment_label',
    'You have pushed the button this many times:',
    '',
  ),
  homeIndexCounterIncrementAction(
    1006,
    'home_index_counter_increment_action',
    'Increment',
    '',
  );

  @override
  final int code;
  @override
  final String key;
  @override
  final String msg;

  @override
  final Map<String, Object> param;

  @override
  final MessageLevel level;

  @override
  final int exit;

  @override
  final String desc;

  const AppMessage(
    this.code,
    this.key,
    this.msg,
    this.desc, {
    // ignore: unused_element_parameter
    this.param = const {},

    // ignore: unused_element_parameter
    this.level = MessageLevel.INFO,

    // ignore: unused_element_parameter
    this.exit = 0,
  });
}
