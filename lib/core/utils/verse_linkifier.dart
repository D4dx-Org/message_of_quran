import 'package:flutter_linkify/flutter_linkify.dart';

class VerseLinkifier extends Linkifier {
  @override
  List<LinkifyElement> parse(
    List<LinkifyElement> elements,
    LinkifyOptions options,
  ) {
    final list = <LinkifyElement>[];
    // This RegEx looks for numbers inside parentheses like (4)
    final regex = RegExp(r'\((\d+)\)');

    for (var element in elements) {
      if (element is TextElement) {
        final matches = regex.allMatches(element.text);
        if (matches.isEmpty) {
          list.add(element);
        } else {
          int lastIndex = 0;
          for (var match in matches) {
            // Add text before the match
            if (match.start > lastIndex) {
              list.add(
                TextElement(element.text.substring(lastIndex, match.start)),
              );
            }
            // Add the clickable verse number
            list.add(LinkableElement(match.group(0)!, match.group(1)!));
            lastIndex = match.end;
          }
          // Add remaining text
          if (lastIndex < element.text.length) {
            list.add(TextElement(element.text.substring(lastIndex)));
          }
        }
      } else {
        list.add(element);
      }
    }
    return list;
  }
}
