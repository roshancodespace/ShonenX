import 'dart:convert';

import 'package:dartotsu_extension_bridge/Services/Sora/FetchV2.dart';
import 'package:fjs/fjs.dart';
import 'package:flutter/services.dart';

import 'SoraExtensions.dart';

late JsEngine engine;
Future<void> initJsEngine() async {
  await LibFjs.init();
  final runtime = await JsAsyncRuntime.withOptions(
    builtin: JsBuiltinOptions.all(),
  );

  final context = await JsAsyncContext.from(runtime: runtime);
  engine = JsEngine(context: context);
  var fetch = FetchV2(engine);
  await engine.init(
    bridge: (JsValue value) async {
      final data = value.value;

      if (data is Map && data['type'] == 'fetchv2') {
        return fetch.handle(data);
      }

      return const JsResult.err(JsError.cancelled('Unknown bridge call'));
    },
  );
  fetch.inject();
  await runtime.setMemoryLimit(limit: BigInt.from(32 * 1024 * 1024));
  await runtime.setGcThreshold(threshold: BigInt.from(8 * 1024 * 1024));
}

Future<void> loadExtensionJs() async {
  final jsSource = await rootBundle.loadString('assets/hianime.js');

  final wrapped =
      '''
$jsSource

export {
  searchResults,
  extractDetails,
  extractEpisodes,
  extractStreamUrl
};
''';

  await engine.declareNewModule(
    module: JsModule(name: 'HiAnime', source: JsCode.code(wrapped)),
  );
}

Future<void> test() async {
  SoraExtensions().fetchAvailableAnimeExtensions([]);

  /*await initJsEngine();
  await loadExtensionJs();
  print('JS Engine initialized and extension loaded.');*/
}

Future<void> run() async {
  final result = await engine.call(
    module: 'HiAnime',
    method: "searchResults",
    params: [const JsValue.string("naruto")],
  );
  var name = (jsonDecode(result.value) as List).first["href"];
  print(result.value);
  var details = await engine.call(
    module: 'HiAnime',
    method: "extractEpisodes",
    params: [JsValue.string(name)],
  );

  print(details.value);

  var episodes = jsonDecode(details.value) as List;
  var stream = await engine.call(
    module: 'HiAnime',
    method: "extractStreamUrl",
    params: [JsValue.string(episodes.first["href"])],
  );
  print("here ${stream.value}");
}
