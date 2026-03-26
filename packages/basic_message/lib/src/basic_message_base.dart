/*
*   **Platform Agnostic**: Core library has zero dependencies on GUI frameworks, making it ideal for both CLI and Flutter.
*   **Intl-Ready**: The `MessageProvider` pattern is explicitly designed to be scanned by `intl_translation`'s `extract_to_arb` tool.
*   **Type Safe**: Uses Dart Generics to ensure that messages provided to `MessageEngine` strictly adhere to the `MessageEnum` contract.
*   **Graceful Fallback**: Automatically renders `defaultMsg` if the engine is not initialized or translation keys are missing, preventing runtime crashes.
*/

import 'package:logging/logging.dart' as logging show Level;

/// alias logging.level
typedef MessageLevel = logging.Level;

/// Defines the contract for all message identifiers.
abstract class MessageEnum {
  /// Unique error or message code.
  int get code;

  /// use exit(code) to exit the process with a specific code.
  int get exit => 0;

  /// Severity level of the message.
  MessageLevel get level => MessageLevel.INFO;

  /// Corresponding ARB resource key.
  String get key;

  /// Default text used if no translation is found.
  String get msg;

  /// The `desc` provides a description of the message usage.
  String get desc => '';

  /// Default arguments for the message.
  Map<String, Object> get param;
}

/// Abstract provider to be implemented by the application.
/// Acts as the source for `intl` translation extraction.
abstract class MessageProvider<T extends MessageEnum> {
  /// Resolves the message to its localized string.
  /// Implementations should use [Intl.message] to define the translation key.
  String resolve(T message, {Map<String, Object>? args});
}

/// Global engine to handle message translation and dispatching.
class MessageEngine {
  static MessageProvider? _provider;

  /// Initializes the engine with a platform-specific provider.
  static void init(MessageProvider provider) {
    _provider = provider;
  }

  /// Translates the given message.
  /// Returns the default message if the engine is uninitialized or key is missing.
  static String tr<T extends MessageEnum>(
    T message, {
    Map<String, Object>? args,
  }) {
    // Merge values from 'args' into 'param', discarding any keys not present in the base 'param' map.
    if (args != null && args.isNotEmpty && message.param.isNotEmpty) {
      final param = Map<String, Object>.from(message.param); // default param

      param.addEntries(
        args.entries.where((entry) => param.containsKey(entry.key)),
      );

      args = param;
    }

    if (_provider == null) {
      return _renderFallback(message.msg, args);
    }
    return _provider!.resolve(message, args: args);
  }

  static String _renderFallback(String msg, Map<String, Object>? args) {
    if (args == null || args.isEmpty) return msg;
    var result = msg;
    args.forEach((key, value) {
      result = result.replaceAll('{$key}', value.toString());
    });
    return result;
  }
}
