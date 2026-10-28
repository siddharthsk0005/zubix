import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

// Channels a brand can link. Keys match `socialLinks` on the backend.
class SocialChannel {
  final String key;
  final String label;
  final FaIconData icon;
  final Color color;
  final bool isPhone;

  const SocialChannel({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    this.isPhone = false,
  });
}

// Display order: Instagram, WhatsApp, YouTube, Facebook, LinkedIn, Call (after the website button).
const List<SocialChannel> socialChannels = [
  SocialChannel(
    key: 'instagram',
    label: 'Instagram',
    icon: FontAwesomeIcons.instagram,
    color: Color(0xFFE1306C),
  ),
  SocialChannel(
    key: 'whatsapp',
    label: 'WhatsApp',
    icon: FontAwesomeIcons.whatsapp,
    color: Color(0xFF25D366),
    isPhone: true,
  ),
  SocialChannel(
    key: 'youtube',
    label: 'YouTube',
    icon: FontAwesomeIcons.youtube,
    color: Color(0xFFFF0000),
  ),
  SocialChannel(
    key: 'facebook',
    label: 'Facebook',
    icon: FontAwesomeIcons.facebook,
    color: Color(0xFF1877F2),
  ),
  SocialChannel(
    key: 'linkedin',
    label: 'LinkedIn',
    icon: FontAwesomeIcons.linkedin,
    color: Color(0xFF0A66C2),
  ),
  SocialChannel(
    key: 'call',
    label: 'Call',
    icon: FontAwesomeIcons.phone,
    color: Color(0xFF111111),
    isPhone: true,
  ),
];

// Builds the link a channel opens. Phone channels become tel:/wa.me links, and bare Instagram handles become instagram.com links.
Uri? socialChannelUri(String key, String value) {
  final v = value.trim();
  if (v.isEmpty) return null;
  final digits = v.replaceAll(RegExp(r'[^0-9+]'), '');

  if (key == 'call') return Uri(scheme: 'tel', path: digits);
  if (key == 'whatsapp') {
    return Uri.parse('https://wa.me/${digits.replaceFirst('+', '')}');
  }
  if (key == 'instagram' && !v.contains('.') && !v.startsWith('http')) {
    return Uri.parse('https://instagram.com/${v.replaceFirst('@', '')}');
  }
  if (v.startsWith('http://') || v.startsWith('https://')) return Uri.parse(v);
  return Uri.parse('https://$v');
}
