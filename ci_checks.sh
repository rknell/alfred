#dart tool/generate_documentation.dart
dart fix --apply
dart analyze --fatal-warnings .
dart format . --fix