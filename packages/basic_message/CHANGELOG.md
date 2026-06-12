## 1.0.1
Fix: refine parameter discovery in gen_msg_resource.dart
 
- Strictly derive parameters from the param map in message enums.
- Prevent false positives when parsing complex ICU message strings (e.g., select labels).
- Improve AST visitor to correctly identify the param argument regardless of its position.
- Use robust string literal parsing for better content extraction.

## 1.0.0

- Initial version.
