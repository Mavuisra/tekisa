library;

import 'package:url_launcher/url_launcher.dart';

const String supportWhatsappPhone = '0821633587';
const String supportDefaultMessage =
    'Bonjour, j\'ai besoin d\'assistance sur l\'application TEKISA.';

Future<bool> openWhatsAppSupport({
  String phone = supportWhatsappPhone,
  String message = supportDefaultMessage,
}) async {
  final cleanPhone = _normalizeDrcPhone(phone);
  if (cleanPhone.isEmpty) return false;
  final encoded = Uri.encodeComponent(message);
  final nativeUri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded');
  if (await _tryLaunch(nativeUri)) return true;

  final waUri = Uri.parse('https://wa.me/$cleanPhone?text=$encoded');
  if (await _tryLaunch(waUri)) return true;

  final fallback = Uri.parse(
    'https://api.whatsapp.com/send?phone=$cleanPhone&text=$encoded',
  );
  if (await _tryLaunch(fallback)) return true;

  return false;
}

Future<bool> _tryLaunch(Uri uri) async {
  try {
    if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return true;
    }
  } catch (_) {
    // fallback sur l'URL suivante
  }
  return false;
}

String _normalizeDrcPhone(String input) {
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return '';
  if (digits.startsWith('243')) return digits;
  if (digits.length == 10 && digits.startsWith('0')) {
    return '243${digits.substring(1)}';
  }
  return digits;
}
