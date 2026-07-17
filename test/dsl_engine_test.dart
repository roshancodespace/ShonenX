import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:html/dom.dart' as dom;
import 'package:shonenx/core/network/http_client.dart';
import 'package:shonenx/source_engine/dsl_engine/dsl_context.dart';
import 'package:shonenx/source_engine/dsl_engine/dsl_runtime.dart';
import 'package:shonenx/source_engine/dsl_engine/expression_evaluator.dart';
import 'package:shonenx/source_engine/dsl_engine/helper_registry.dart';
import 'package:shonenx/source_engine/dsl_engine/step_registry.dart';

class FakeHTTP implements HTTP {
  final Map<String, HttpResponse> responses = {};

  @override
  Future<HttpResponse> get(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Duration? cacheDuration = Duration.zero,
  }) async {
    return responses[url] ?? HttpResponse(200, '{}');
  }

  @override
  Future<HttpResponse> post(
    String url, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
    Object? body,
    Duration? cacheDuration,
  }) async {
    return responses[url] ?? HttpResponse(200, '{}');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('DSL Expression Evaluator Tests', () {
    late ExecutionContext context;
    late HelperRegistry helpers;
    late FakeHTTP fakeHttp;

    setUp(() {
      fakeHttp = FakeHTTP();
      helpers = HelperRegistry(client: fakeHttp);
      context = ExecutionContext();
    });

    test('Test literal parsing', () async {
      expect(await ExpressionEvaluator.evaluate("'hello'", context, helpers), 'hello');
      expect(await ExpressionEvaluator.evaluate('123', context, helpers), 123);
      expect(await ExpressionEvaluator.evaluate('true', context, helpers), true);
    });

    test('Test simple variable resolution', () async {
      context.setVariable('title', 'One Piece');
      expect(await ExpressionEvaluator.evaluate('title', context, helpers), 'One Piece');
    });

    test('Test dotted variable property resolution', () async {
      context.setVariable('item', {
        'attributes': {'title': 'Naruto'}
      });
      expect(await ExpressionEvaluator.evaluate('item.attributes.title', context, helpers), 'Naruto');
    });

    test('Test bracket array resolution', () async {
      context.setVariable('items', [
        {'title': 'Bleach'},
        {'title': 'One Piece'}
      ]);
      expect(await ExpressionEvaluator.evaluate('items.1.title', context, helpers), 'One Piece');
    });

    test('Test helper function execution', () async {
      context.setVariable('name', '  Goku  ');
      final result = await ExpressionEvaluator.evaluate('trim(name)', context, helpers);
      expect(result, 'Goku');
    });

    test('Test nested helper functions', () async {
      context.setVariable('name', '  GoKu  ');
      final result = await ExpressionEvaluator.evaluate('lowercase(trim(name))', context, helpers);
      expect(result, 'goku');
    });

    test('Test string templates interpolation', () async {
      context.setVariable('query', 'Naruto');
      context.setVariable('page', 2);
      final url = await ExpressionEvaluator.evaluateTemplate(
        'https://example.com/search?q={{query}}&p={{page}}',
        context,
        helpers,
      );
      expect(url, 'https://example.com/search?q=Naruto&p=2');
    });

    test('Test direct expression returns in templates', () async {
      context.setVariable('items', ['a', 'b']);
      final direct = await ExpressionEvaluator.evaluateTemplate('{{items}}', context, helpers);
      expect(direct, isA<List>());
      expect(direct.length, 2);
    });
  });

  group('DSL Helper Registry Tests', () {
    late ExecutionContext context;
    late HelperRegistry helpers;
    late FakeHTTP fakeHttp;

    setUp(() {
      fakeHttp = FakeHTTP();
      helpers = HelperRegistry(client: fakeHttp);
      context = ExecutionContext();
    });

    test('regex helper', () async {
      final result = await helpers.execute('regex', ['Title (2024)', r'\((\d+)\)', 1], context);
      expect(result, '2024');
    });

    test('joinUrl helper', () async {
      expect(await helpers.execute('joinUrl', ['https://api.com/', '/search'], context), 'https://api.com/search');
      expect(await helpers.execute('joinUrl', ['https://api.com', 'search'], context), 'https://api.com/search');
    });

    test('jsonPath helper', () async {
      final obj = {
        'results': [
          {'name': 'A'},
          {'name': 'B'}
        ]
      };
      expect(await helpers.execute('jsonPath', [obj, 'results[1].name'], context), 'B');
    });
  });

  group('DSL Runtime End-to-End Pipeline Tests', () {
    late DSLRuntime runtime;
    late FakeHTTP fakeHttp;

    setUp(() {
      fakeHttp = FakeHTTP();
      runtime = DSLRuntime(httpClient: fakeHttp);
    });

    test('E2E search pipeline simulation', () async {
      const mockHtml = '''
        <div class="list">
          <div class="item">
            <a href="/anime/one-piece">One Piece</a>
            <img src="/covers/one-piece.jpg" />
          </div>
          <div class="item">
            <a href="/anime/naruto">Naruto</a>
            <img src="/covers/naruto.jpg" />
          </div>
        </div>
      ''';

      fakeHttp.responses['https://source.com/search?q=One'] = HttpResponse(200, mockHtml);

      final providerDef = {
        'id': 'my_test_source',
        'name': 'Test Source',
        'baseUrl': 'https://source.com',
        'methods': {
          'search': {
            'steps': [
              {
                'type': 'get',
                'url': '{{baseUrl}}/search?q={{query}}'
              },
              {
                'type': 'html'
              },
              {
                'type': 'select',
                'selector': 'div.item',
                'all': true,
                'output': 'elements'
              },
              {
                'type': 'map',
                'input': '{{elements}}',
                'itemVar': 'item',
                'steps': [
                  {
                    'type': 'object',
                    'fields': {
                      'id': '{{attr(select(item, "a"), "href")}}',
                      'title': '{{text(select(item, "a"))}}',
                      'cover': '{{absoluteUrl(baseUrl, attr(select(item, "img"), "src"))}}'
                    }
                  }
                ]
              }
            ]
          }
        }
      };

      final result = await runtime.executeMethod(providerDef, 'search', {'query': 'One'});

      expect(result, isA<List>());
      final list = result as List;
      expect(list.length, 2);

      expect(list[0]['id'], '/anime/one-piece');
      expect(list[0]['title'], 'One Piece');
      expect(list[0]['cover'], 'https://source.com/covers/one-piece.jpg');

      expect(list[1]['id'], '/anime/naruto');
      expect(list[1]['title'], 'Naruto');
      expect(list[1]['cover'], 'https://source.com/covers/naruto.jpg');
    });
  });
}
