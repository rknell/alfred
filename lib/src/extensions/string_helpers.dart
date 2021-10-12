enum DecodeMode { AllButSlash, SlashOnly }

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

  static final int _PERCENT = '%'.codeUnitAt(0);
  static final int _SLASH = '/'.codeUnitAt(0);
  static final int _ZERO = '0'.codeUnitAt(0);
  static final int _NINE = '9'.codeUnitAt(0);
  static final int _UPPER_A = 'A'.codeUnitAt(0);
  static final int _UPPER_F = 'F'.codeUnitAt(0);
  static final int _LOWER_A = 'a'.codeUnitAt(0);
  static final int _LOWER_F = 'f'.codeUnitAt(0);

  int _decodeHex(int codeUnit) {
    if (_ZERO <= codeUnit && codeUnit <= _NINE) {
      return codeUnit - _ZERO;
    }
    if (_LOWER_A <= codeUnit && codeUnit <= _LOWER_F) {
      return 10 + codeUnit - _LOWER_A;
    } else if (_UPPER_A <= codeUnit && codeUnit <= _UPPER_F) {
      return 10 + codeUnit - _UPPER_A;
    } else {
      return -1;
    }
  }

  int? _getCodeUnit(int hex1, int hex2) {
    if (hex1 < 0 || hex1 >= 16) return null;
    if (hex2 < 0 || hex2 >= 16) return null;
    return 16 * hex1 + hex2;
  }

  bool _decode(int? codeUnit, DecodeMode mode) {
    if (codeUnit == null) return false;
    switch (mode) {
      case DecodeMode.AllButSlash:
        return codeUnit != _SLASH;
      case DecodeMode.SlashOnly:
        return codeUnit == _SLASH;
    }
  }

  String decodeUri(DecodeMode mode) {
    var codes = codeUnits;
    var changed = false;
    var pos = 0;
    while (pos < codes.length) {
      final char = codes[pos];
      if (char == _PERCENT) {
        if (pos + 2 >= length) break;
        final hex1 = _decodeHex(codes[pos + 1]);
        final hex2 = _decodeHex(codes[pos + 2]);
        final codeUnit = _getCodeUnit(hex1, hex2);
        if (_decode(codeUnit, mode)) {
          if (!changed) {
            // make a copy
            codes = codes.toList();
            changed = true;
          }
          codes[pos] = codeUnit!;
          codes.removeRange(pos + 1, pos + 3);
        }
      }
      pos++;
    }
    return changed ? String.fromCharCodes(codes) : this;
  }
}
