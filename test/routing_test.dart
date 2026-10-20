import 'package:flutter_test/flutter_test.dart';
import 'package:zubix/main.dart';

void main() {
  group('resolveWebRoute', () {
    test('serves each audience route exactly', () {
      expect(resolveWebRoute('/'), '/');
      expect(resolveWebRoute('/admin'), '/admin');
      expect(resolveWebRoute('/brands'), '/brands');
      expect(resolveWebRoute('/brands/register'), '/brands/register');
    });

    test('ignores case and trailing slashes', () {
      expect(resolveWebRoute('/Admin'), '/admin');
      expect(resolveWebRoute('/ADMIN/'), '/admin');
      expect(resolveWebRoute('/brands/register/'), '/brands/register');
    });

    test('falls back to the consumer route for unknown paths', () {
      expect(resolveWebRoute('/brands/login'), '/');
      expect(resolveWebRoute('/admin/users'), '/');
      expect(resolveWebRoute('/dashboard'), '/');
      expect(resolveWebRoute(''), '/');
    });

    test('does not treat the root as an extra trailing-slash case', () {
      expect(normalizeWebRoute('/'), '/');
      expect(webRoutes, contains('/'));
    });
  });
}
