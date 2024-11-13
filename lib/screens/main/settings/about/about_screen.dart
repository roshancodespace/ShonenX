import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        leading: IconButton(onPressed: () => Navigator.pop(context), icon: Icon(Icons.navigate_before, size: 35,)),
        title: Text('About', style: Theme.of(context).textTheme.headlineLarge,),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.0),
            Center(
              child: Image.asset(
                'lib/assets/images/onboarding/logo.png',
                width: 100,
                height: 100,
              ),
            ),
            SizedBox(height: 24.0),
            Text(
              'ShonenX',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 8.0),
            Text(
              'Version Beta',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            SizedBox(height: 24.0),
            Text(
              'About',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 8.0),
            Text(
              'This is an example Flutter app. It demonstrates how to create an About screen with information about the app, such as the name, version, and a brief description.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 24.0),
            Text(
              'Contact',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 8.0),
            Text(
              'For any questions or feedback, please contact us at darkx.dev.23@gmail.com',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Spacer(),
            Center(
              child: TextButton(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: 'darkx.dev.23@gmail.com'));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Email address copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: Text('Copy Email'),
              ),
            ),
            SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}