import 'package:test/test.dart';

import 'package:alfred/alfred.dart';

void main() {
  test('it should normalize path', () {
    expect('/test'.normalizePath, 'test');
    expect('test/'.normalizePath, 'test');
    expect('/test/'.normalizePath, 'test');
    expect('//test'.normalizePath, 'test');
    expect('test//'.normalizePath, 'test');
    expect('//test//'.normalizePath, 'test');
    expect('/multiple/segments/'.normalizePath, 'multiple/segments');
    expect('//multiple//segments//'.normalizePath, 'multiple//segments');
  });

  test('it should decode URI path except for "%2F" (slash)', () {
    // first make sure Uri.parse() behaves as expected
    expect(Uri.parse('/%31').path, '/1');
    expect(Uri.parse('/%61').path, '/a');
    expect(Uri.parse('/%6').path,
        '/%256'); // invalid escape sequences have their percent character encoded when parsed
    expect(Uri.parse('/abc%20def/').path,
        '/abc%20def/'); // %20 is not decoded (space ' ')
    expect(Uri.parse('/abc%25def/').path,
        '/abc%25def/'); // %25 is not decoded (percent '%')
    expect(Uri.parse('/abc%2Fdef/').path,
        '/abc%2Fdef/'); // %2F is not decoded (slash '/')
    expect(Uri.parse('/abc%3Fdef/').path,
        '/abc%3Fdef/'); // %3F is not decoded (question mark '?')

    // before matching, URI path must be decoded except for "%2F"
    expect(_decodePath('/%61'), 'a');
    expect(_decodePath('/%61bc'), 'abc');
    expect(_decodePath('/%61bc/def/'), 'abc/def');
    expect(_decodePath('/%6'), '%6');
    expect(_decodePath('/abc%20def/'),
        'abc def'); // decode escape sequence for space ' '
    expect(_decodePath('/abc%25def/'),
        'abc%def'); // decode escape sequence for percent '%'
    expect(_decodePath('/abc%2Fdef/'),
        'abc%2Fdef'); // do not decode escape sequence for slash '/'
    expect(_decodePath('/abc%3Fdef/'),
        'abc?def'); // decode escape sequence for question mark '?'

    // after matching, a segment containing %2F must be decoded
    expect(_decodeSegment('abc%2Fdef'), 'abc/def');
    expect(_decodeSegment('abc%31'), 'abc%31'); // eg. from path /abc%2531/
  });
}

String _decodePath(String path) =>
    Uri.parse(path).path.normalizePath.decodeUri(DecodeMode.AllButSlash);

String _decodeSegment(String segment) =>
    segment.decodeUri(DecodeMode.SlashOnly);
