import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:universal_html/html.dart' as html;

class SeoMeta {
  static void set({required String title, required String description, String? path, String? image}) {
    if (!kIsWeb) return;
    final doc = html.document;
    doc.title = title;
    _setMeta('name', 'description', description);
    _setMeta('property', 'og:title', title);
    _setMeta('property', 'og:description', description);
    if (image != null) _setMeta('property', 'og:image', image);
    if (path != null) {
      final origin = html.window.location.origin;
      _setMeta('property', 'og:url', '$origin$path');
      _setLink('canonical', '$origin$path');
    }
    _setMeta('name', 'twitter:card', 'summary');
    _setMeta('name', 'twitter:title', title);
    _setMeta('name', 'twitter:description', description);
    if (image != null) _setMeta('name', 'twitter:image', image);
  }

  static void _setMeta(String attr, String key, String content) {
    final head = html.document.head!;
    final exist = head.querySelector('meta[$attr="$key"]');
    final el = (exist as html.MetaElement?) ?? html.MetaElement()..setAttribute(attr, key);
    el.content = content;
    if (el.parent == null) head.append(el);
  }

  static void _setLink(String rel, String href) {
    final head = html.document.head!;
    final exist = head.querySelector('link[rel="$rel"]');
    final el = (exist as html.LinkElement?) ?? html.LinkElement()..rel = rel;
    el.href = href;
    if (el.parent == null) head.append(el);
  }
}
