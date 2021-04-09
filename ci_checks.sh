dart tool/generate_documentation.dart
dart fix --apply
dartanalyzer --fatal-warnings lib test example
dartfmt -w .
sh generateCoverage.sh