import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InAppWebViewDebugScreen extends StatelessWidget {
  const InAppWebViewDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: InAppWebView(
        onConsoleMessage: (controller, consoleMessage) {
          print(consoleMessage);
        },
        initialUrlRequest: URLRequest(
          url: WebUri("https://accounts.google.co.in/"),
        ),
      ),
    );
  }
}
