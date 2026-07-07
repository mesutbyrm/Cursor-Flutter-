import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Inline SVG ikonlar — harici asset gerekmez.
abstract final class VoiceRoomsSvgIcons {
  static Widget icon(
    String key, {
    double size = 24,
    Color color = Colors.white,
  }) {
    return SvgPicture.string(
      _paths[key] ?? _paths['mic']!,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  static const _paths = <String, String>{
    'soundwave': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="2" y="9" width="3" height="6" rx="1.5" fill="currentColor"/>
<rect x="7" y="5" width="3" height="14" rx="1.5" fill="currentColor"/>
<rect x="12" y="7" width="3" height="10" rx="1.5" fill="currentColor"/>
<rect x="17" y="3" width="3" height="18" rx="1.5" fill="currentColor"/>
</svg>''',
    'search': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="2"/>
<path d="M20 20L16 16" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>''',
    'trophy': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M6 4H18V8C18 11 16 13 13 13H11C8 13 6 11 6 8V4Z" stroke="currentColor" stroke-width="2"/>
<path d="M12 13V17M8 20H16M9 17H15" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
<path d="M4 6H6M18 6H20" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>''',
    'bell': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 3C9 3 7 5.5 7 8.5V12L5 15H19L17 12V8.5C17 5.5 15 3 12 3Z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
<path d="M10 18C10 19.1 10.9 20 12 20C13.1 20 14 19.1 14 18" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>''',
    'fire': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 22C16 18 18 15 18 11C18 7 15 4 12 2C12 5 10 7 8 9C6 11 5 13 5 15C5 19 8 22 12 22Z" fill="currentColor"/>
</svg>''',
    'chat': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M4 5H20V16H8L4 20V5Z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
</svg>''',
    'music': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9 18V6L21 3V15" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
<circle cx="6" cy="18" r="3" stroke="currentColor" stroke-width="2"/>
<circle cx="18" cy="15" r="3" stroke="currentColor" stroke-width="2"/>
</svg>''',
    'heart': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 21C12 21 3 14.5 3 8.5C3 5.5 5.5 3 8.5 3C10.2 3 11.7 3.8 12 5.1C12.3 3.8 13.8 3 15.5 3C18.5 3 21 5.5 21 8.5C21 14.5 12 21 12 21Z" fill="currentColor"/>
</svg>''',
    'game': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="3" y="8" width="18" height="10" rx="4" stroke="currentColor" stroke-width="2"/>
<path d="M8 11V15M6 13H10" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
<circle cx="16" cy="12" r="1" fill="currentColor"/>
<circle cx="18" cy="14" r="1" fill="currentColor"/>
</svg>''',
    'moon': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M21 14.5C20 15.5 18.5 16 17 16C13.1 16 10 12.9 10 9C10 7.5 10.5 6 11.5 5C8 5.5 5.5 8.5 5.5 12C5.5 16.4 9.1 20 13.5 20C17 20 19.5 17.5 21 14.5Z" fill="currentColor"/>
</svg>''',
    'mic': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="9" y="3" width="6" height="11" rx="3" stroke="currentColor" stroke-width="2"/>
<path d="M5 11C5 14.9 8.1 18 12 18C15.9 18 19 14.9 19 11" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
<path d="M12 18V21M8 21H16" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>''',
    'headphones': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M4 14V11C4 6.6 7.6 3 12 3C16.4 3 20 6.6 20 11V14" stroke="currentColor" stroke-width="2"/>
<rect x="2" y="13" width="5" height="8" rx="2" stroke="currentColor" stroke-width="2"/>
<rect x="17" y="13" width="5" height="8" rx="2" stroke="currentColor" stroke-width="2"/>
</svg>''',
    'home': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M4 10.5L12 4L20 10.5V20C20 20.6 19.6 21 19 21H5C4.4 21 4 20.6 4 20V10.5Z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
</svg>''',
    'shorts': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect x="4" y="3" width="16" height="18" rx="3" stroke="currentColor" stroke-width="2"/>
<path d="M10 8.5L16 12L10 15.5V8.5Z" fill="currentColor"/>
</svg>''',
    'live': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="4" fill="currentColor"/>
<path d="M7 7C5 9 4 11.5 4 14C4 16.5 5 19 7 21M17 7C19 9 20 11.5 20 14C20 16.5 19 19 17 21" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>''',
    'profile': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="8" r="4" stroke="currentColor" stroke-width="2"/>
<path d="M5 20C5 16.1 8.1 13 12 13C15.9 13 19 16.1 19 20" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>''',
    'sparkle': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 2L13.5 9.5L21 11L13.5 12.5L12 20L10.5 12.5L3 11L10.5 9.5L12 2Z" fill="currentColor"/>
</svg>''',
    'hand': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M7 11V6C7 4.9 7.9 4 9 4C10.1 4 11 4.9 11 6V11M11 11V5C11 3.9 11.9 3 13 3C14.1 3 15 3.9 15 5V11M15 11V7C15 5.9 15.9 5 17 5C18.1 5 19 5.9 19 7V13C19 17.4 15.4 21 11 21H9C5.7 21 3 18.3 3 15V12C3 10.9 3.9 10 5 10C6.1 10 7 10.9 7 12" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''',
    'play': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<circle cx="12" cy="12" r="10" fill="currentColor" fill-opacity="0.2" stroke="currentColor" stroke-width="2"/>
<path d="M10 8L16 12L10 16V8Z" fill="currentColor"/>
</svg>''',
    'playlist': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M4 7H16M4 12H13M4 17H11" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
<circle cx="18" cy="15" r="4" stroke="currentColor" stroke-width="2"/>
<path d="M18 13V15L19.5 16" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
</svg>''',
    'chevron_down': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M6 9L12 15L18 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''',
    'chevron_right': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M9 6L15 12L9 18" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
</svg>''',
    'location': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 21C12 21 18 15 18 10C18 6.7 15.3 4 12 4C8.7 4 6 6.7 6 10C6 15 12 21 12 21Z" stroke="currentColor" stroke-width="2"/>
<circle cx="12" cy="10" r="2.5" stroke="currentColor" stroke-width="2"/>
</svg>''',
    'eye': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M2 12C2 12 5.5 5 12 5C18.5 5 22 12 22 12C22 12 18.5 19 12 19C5.5 19 2 12 2 12Z" stroke="currentColor" stroke-width="2"/>
<circle cx="12" cy="12" r="3" stroke="currentColor" stroke-width="2"/>
</svg>''',
    'diamond': '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
<path d="M12 3L20 9L12 21L4 9L12 3Z" stroke="currentColor" stroke-width="2" stroke-linejoin="round"/>
</svg>''',
  };
}
