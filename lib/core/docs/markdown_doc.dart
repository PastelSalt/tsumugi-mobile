/// Parsing of the bundled Markdown documents (website `lib/markdown.jsx` `parseDocument`).
/// A document has a title (`# `), an intro with `**Key:** value` metadata and a `>` notice,
/// then numbered sections (`## `).
class MarkdownSection {
  const MarkdownSection({
    required this.heading,
    required this.id,
    required this.body,
  });

  /// Heading as written, e.g. "1. Who this notice applies to".
  final String heading;
  final String id;

  /// Section body as Markdown (the lines after the heading).
  final String body;

  /// Heading without its leading number, e.g. "Who this notice applies to".
  String get plainHeading => heading.replaceFirst(RegExp(r'^\d+\.\s*'), '');

  /// The leading section number ("01"), or null when the heading is not numbered.
  String? get number {
    final m = RegExp(r'^(\d+)\.\s*').firstMatch(heading);
    return m?.group(1)?.padLeft(2, '0');
  }
}

class MarkdownDoc {
  const MarkdownDoc({
    required this.title,
    required this.meta,
    required this.notice,
    required this.sections,
  });

  final String title;

  /// `**Key:** value` pairs from the intro, in order.
  final List<(String key, String value)> meta;

  /// Text of the `>` notice in the intro.
  final String notice;
  final List<MarkdownSection> sections;
}

String slugify(String text) => text
    .toLowerCase()
    .replaceFirst(RegExp(r'^\d+\.\s*'), '')
    .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
    .replaceAll(RegExp(r'^-+|-+$'), '');

MarkdownDoc parseDocument(String source) {
  final lines = source.replaceAll('\r\n', '\n').split('\n');
  final titleLine = lines.firstWhere(
    (l) => l.startsWith('# '),
    orElse: () => '# Untitled',
  );
  final firstSection = lines.indexWhere((l) => l.startsWith('## '));
  final introEnd = firstSection == -1 ? lines.length : firstSection;

  final meta = <(String, String)>[];
  final notice = <String>[];
  for (final line in lines.sublist(0, introEnd)) {
    final pair = RegExp(r'^\*\*([^*]+):\*\*\s*(.*?)\s*$').firstMatch(line);
    if (pair != null) {
      meta.add((pair.group(1)!, pair.group(2)!));
    } else if (line.startsWith('>')) {
      notice.add(line.replaceFirst(RegExp(r'^>\s?'), ''));
    }
  }

  final headings = <String>[];
  final bodies = <List<String>>[];
  for (final line in lines.sublist(introEnd)) {
    if (line.startsWith('## ')) {
      headings.add(line.substring(3).trim());
      bodies.add(<String>[]);
    } else if (bodies.isNotEmpty) {
      bodies.last.add(line);
    }
  }
  final sections = [
    for (var i = 0; i < headings.length; i++)
      MarkdownSection(
        heading: headings[i],
        id: slugify(headings[i]),
        body: bodies[i].join('\n').trim(),
      ),
  ];

  return MarkdownDoc(
    title: titleLine.substring(2).trim(),
    meta: meta,
    notice: notice.join(' ').trim(),
    sections: sections,
  );
}
