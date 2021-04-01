dart tool/generate_readme.dart
pub run test --platform vm
dartanalyzer --fatal-warnings lib test example
dartfmt -w .
sh generateCoverage.sh