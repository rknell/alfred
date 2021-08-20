extension PathNormalizer on String {
  /// Trims all slashes at the start and end
  String get normalizePath {
    if (startsWith('/')) {
      return substring('/'.length).normalizePath;
    }
    if (endsWith('/')) {
      return substring(0, length - '/'.length).normalizePath;
    }
    return this;
  }
}
