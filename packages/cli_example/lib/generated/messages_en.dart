// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.
// @dart=2.12
// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = MessageLookup();

typedef String? MessageIfAbsent(
    String? messageStr, List<Object>? args);

class MessageLookup extends MessageLookupByLibrary {
  @override
  String get localeName => 'en';

  static m0(count) => "${Intl.plural(count, one: 'has one apple', other: 'has ${count} apples')}";

  static m1(whose, apple) => "${whose} ${apple}";

  static m2(gender) => "${Intl.gender(gender, female: 'She', male: 'He', other: 'They')}";

  static m3(username) => "Welcome, ${username}!";

  @override
  final Map<String, dynamic> messages = _notInlinedMessages(_notInlinedMessages);

  static Map<String, dynamic> _notInlinedMessages(Object? _) => {
      'common_global_action_confirm_exit_label': MessageLookupByLibrary.simpleMessage('Are you sure to exit?'),
    'common_global_body_apple_label': m0,
    'common_global_body_assembleWhoseApple_label': m1,
    'common_global_body_gender_label': m2,
    'home_index_counter_increment_action': MessageLookupByLibrary.simpleMessage('Increment'),
    'home_index_counter_increment_label': MessageLookupByLibrary.simpleMessage('You have pushed the button this many times:'),
    'home_index_header_default_title': MessageLookupByLibrary.simpleMessage('Multi Language Home Page'),
    'home_index_header_welcome_label': m3
  };
}
