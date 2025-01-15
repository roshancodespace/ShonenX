import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutScreen extends StatelessWidget {
  final String githubUrl = 'https://github.com/Darkx-dev/ShonenX';
  final String email = 'darkx.dev.23@gmail.com';
  final String instagramUrl = 'https://www.instagram.com/darkx.dev.23/';
  final String telegramUrl = 'https://t.me/dark_dev_23';
  final String title;
  const AboutScreen({super.key, required this.title});

  void _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        title: Hero(
          tag: ValueKey(title),
          child: Text(
            'About',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 24.0),
            Center(
              // child: Image.asset(
              //   'lib/assets/images/onboarding/logo.png',
              //   width: 120,
              //   height: 120,
              // ),
              child: SvgPicture.asset(
                'lib/assets/images/onboarding/logo.svg',
                colorFilter: ColorFilter.mode(
                  Theme.of(context).colorScheme.primary, // The desired color
                  BlendMode.srcIn,
                ),
                width: 120,
                height: 120,
              ),
            ),
            SizedBox(height: 24.0),
            Center(
              child: Text(
                'ShonenX',
                style: Theme.of(context)
                    .textTheme
                    .headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 8.0),
            Center(
              child: Text(
                'Version: Beta',
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(color: Colors.grey),
              ),
            ),
            SizedBox(height: 32.0),
            Text(
              'About ShonenX',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 8.0),
            Text(
              'ShonenX is a Flutter app in beta development, showcasing an evolving project with exciting features. Expect future updates as bugs are resolved and functionality expands.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 24.0),
            Text(
              'Developer',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 8.0),
            Text(
              'Developed by Roshan Kumar. For any feedback or queries, feel free to reach out.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 8.0),
            Text(
              'GitHub Repository:',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: githubUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('GitHub link copied to clipboard'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                githubUrl,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
              ),
            ),
            SizedBox(height: 24.0),
            Text(
              'Contact',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 8.0),
            Text(
              email,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedMail01,
                    color: Theme.of(context).iconTheme.color!,
                  ),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: email));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Email address copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedInstagram,
                    color: Theme.of(context).iconTheme.color!,
                  ),
                  onPressed: () => _launchUrl(instagramUrl),
                ),
                IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedTelegram,
                    color: Theme.of(context).iconTheme.color!,
                  ),
                  onPressed: () => _launchUrl(telegramUrl),
                ),
              ],
            ),
            SizedBox(height: 16.0),
          ],
        ),
      ),
    );
  }
}
