dart tool/generate_documentation.dart
dart fix --apply
dartanalyzer --fatal-warnings .
dartfmt -w .
sh generateCoverage.sh