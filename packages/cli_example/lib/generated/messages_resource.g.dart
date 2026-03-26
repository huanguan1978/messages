// Generated code. DO NOT EDIT.

// ignore_for_file: non_constant_identifier_names

import 'package:intl/intl.dart';

class L10nResource {
  static String common_global_body_gender_label(Object? gender) {
    gender = gender ?? 'male';
    return Intl.message(
      '{gender, select, male{He} female{She} other{They}}',
      name: 'common_global_body_gender_label',
      args: [gender],
      examples: const {'gender': 'male'},
      desc: 'gobal gender (male | female) to (He | She).',
    );
  }

  static String common_global_body_apple_label(Object? count) {
    count = count ?? '5';
    return Intl.message(
      '{count, plural, =1{has one apple} other{has {count} apples}}',
      name: 'common_global_body_apple_label',
      args: [count],
      examples: const {'count': '5'},
    );
  }

  static String common_global_body_assembleWhoseApple_label(
    Object? whose,
    Object? apple,
  ) {
    whose = whose ?? 'male';
    apple = apple ?? '5';
    return Intl.message(
      '{whose} {apple}',
      name: 'common_global_body_assembleWhoseApple_label',
      args: [whose, apple],
      examples: const {'whose': 'male', 'apple': '5'},
      desc: 'assemble whose apple.',
    );
  }

  static String common_global_action_confirm_exit_label() {
    return Intl.message(
      'Are you sure to exit?',
      name: 'common_global_action_confirm_exit_label',
      desc: 'cli exit tips.',
    );
  }

  static String home_index_header_welcome_label(Object? username) {
    username = username ?? 'Guest';
    return Intl.message(
      'Welcome, {username}!',
      name: 'home_index_header_welcome_label',
      args: [username],
      examples: const {'username': 'Guest'},
    );
  }

  static String home_index_header_default_title() {
    return Intl.message(
      'Multi Language Home Page',
      name: 'home_index_header_default_title',
    );
  }

  static String home_index_counter_increment_label() {
    return Intl.message(
      'You have pushed the button this many times:',
      name: 'home_index_counter_increment_label',
    );
  }

  static String home_index_counter_increment_action() {
    return Intl.message(
      'Increment',
      name: 'home_index_counter_increment_action',
    );
  }
}
