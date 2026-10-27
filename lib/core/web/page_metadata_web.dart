import 'package:web/web.dart' as web;

void updatePageMetadata(String title, String description) {
  web.document.title = title;
  web.document
      .querySelector('meta[name="description"]')
      ?.setAttribute('content', description);
  web.document
      .querySelector('meta[property="og:title"]')
      ?.setAttribute('content', title);
  web.document
      .querySelector('meta[property="og:description"]')
      ?.setAttribute('content', description);
}

String formHoneypotValue() =>
    (web.document.getElementById('form-website') as web.HTMLInputElement?)
        ?.value ??
    '';
