dart tool/generate_readme.dart
dartanalyzer --fatal-warnings lib test example
dartfmt -w .
sh generateCoverage.sh