import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:rhttp/rhttp.dart';
import 'package:shonenx/core/network/doh/doh_cache.dart';
import 'package:shonenx/core/network/doh/doh_provider.dart';
import 'package:shonenx/core/network/doh/doh_resolver.dart';
import 'package:shonenx/core/network/http_client.dart';

void main() {
  setUpAll(() async {
    await Rhttp.init();
  });

  group('DohCache Tests', () {
    test('Stores and retrieves non-expired DNS entries', () {
      final cache = DohCache();
      cache.put('example.com', ['93.184.216.34'], ttlSeconds: 100);

      final retrieved = cache.get('example.com');
      expect(retrieved, ['93.184.216.34']);
    });

    test('Enforces minimum and maximum TTL bounds', () {
      final cache = DohCache();
      // Should clamp to minTtlSeconds (60s)
      cache.put('low-ttl.com', ['1.2.3.4'], ttlSeconds: 5);
      expect(cache.get('low-ttl.com'), isNotNull);

      // Should clamp to maxTtlSeconds (3600s)
      cache.put('high-ttl.com', ['5.6.7.8'], ttlSeconds: 99999);
      expect(cache.get('high-ttl.com'), isNotNull);
    });

    test('Clears all entries', () {
      final cache = DohCache();
      cache.put('a.com', ['1.1.1.1']);
      cache.put('b.com', ['2.2.2.2']);
      expect(cache.size, 2);

      cache.clear();
      expect(cache.size, 0);
      expect(cache.get('a.com'), isNull);
    });
  });

  group('DohResolver Unit Tests', () {
    late DohResolver resolver;

    setUp(() {
      resolver = DohResolver();
    });

    tearDown(() {
      resolver.dispose();
    });

    test('Defaults to Cloudflare provider', () {
      expect(resolver.currentProvider, DohProvider.cloudflare);
    });

    test('Short-circuits IP addresses directly', () async {
      final ipv4 = await resolver.resolve('192.168.1.1');
      expect(ipv4, ['192.168.1.1']);

      final ipv6 = await resolver.resolve('::1');
      expect(ipv6, ['::1']);
    });

    test('Short-circuits localhost domains to 127.0.0.1', () async {
      final res = await resolver.resolve('localhost');
      expect(res, ['127.0.0.1']);

      final localSub = await resolver.resolve('test.local');
      expect(localSub, ['127.0.0.1']);
    });

    test('Resolves bootstrap hosts without network query', () async {
      final res = await resolver.resolve('cloudflare-dns.com');
      expect(res, contains('1.1.1.1'));
    });

    test('Resolves domain via Cloudflare DoH', () async {
      resolver.setProvider(DohProvider.cloudflare);
      final ips = await resolver.resolve('google.com');
      expect(ips, isNotEmpty);
      expect(InternetAddress.tryParse(ips.first), isNotNull);
    });

    test('Resolves domain via Google DoH', () async {
      resolver.setProvider(DohProvider.google);
      final ips = await resolver.resolve('google.com');
      expect(ips, isNotEmpty);
      expect(InternetAddress.tryParse(ips.first), isNotNull);
    });

    test('Resolves domain via System DNS when configured', () async {
      resolver.setProvider(DohProvider.system);
      final ips = await resolver.resolve('google.com');
      expect(ips, isNotEmpty);
      expect(InternetAddress.tryParse(ips.first), isNotNull);
    });

    test('TestLookup diagnostic helper returns latency and success', () async {
      final res = await resolver.testLookup(domain: 'google.com');
      expect(res.success, isTrue);
      expect(res.latencyMs, greaterThan(0));
      expect(res.addresses, isNotEmpty);
      expect(res.provider, DohProvider.cloudflare);
    });
  });

  group('HTTP client integration with DoH', () {
    test('HTTP client performs requests through injected DoH resolver', () async {
      final http = HTTP();
      final res = await http.get('https://example.com');
      expect(res.statusCode, 200);
      expect(res.body, contains('Example Domain'));
    });
  });
}
