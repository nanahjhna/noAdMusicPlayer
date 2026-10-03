# noAdMusicPlayer

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## AdMob app-ads.txt

`web/app-ads.txt` is the canonical AdMob authorization file. The Firebase
Hosting workflows copy it into `build/web` before deployment, where it is
available at:

`https://no-ad-music-player.web.app/app-ads.txt`

To verify a deployment, open that URL and confirm it returns the exact
publisher line shown in AdMob under **app-ads.txt** setup, as plain text. The
developer website in the Google Play listing should use the same domain. After
publishing or correcting the file, use AdMob's recheck action and allow time
for Google's crawler to revisit the site.
