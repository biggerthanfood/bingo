import 'package:url_launcher/url_launcher.dart';

class MapsService {
  static Future<void> openAppleMaps({
    required double latitude,
    required double longitude,
    required String name,
  }) async {
    final url = 'http://maps.apple.com/?q=${Uri.encodeFull(name)}&ll=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }
}