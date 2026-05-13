import 'package:flutter/material.dart';

/// Keywords that receive a blue highlighter background when displayed
/// in the BYB handdrawn info text style.
const List<String> _highlightKeywords = [
  'NEURONS', // must come before NEURON to match longest first
  'NEURON',
  'SYNAPSES',
  'SYNAPSE',
  'SPIKING',
  'SPIKES',
  'SPIKE',
  'AXONS',
  'AXON',
];

/// A highlighted-text widget that renders info text in the BybHanddrawn font
/// with ALL text uppercased and specific neuroscience keywords highlighted
/// with a semi-transparent blue background (like a marker highlighter).
///
/// Usage:
/// ```dart
/// BybHighlightedText(
///   "When the NEURON sends a SPIKE, lights will glow!",
///   fontSize: 16,
/// )
/// ```
class BybHighlightedText extends StatelessWidget {
  final String text;
  final double fontSize;
  final Color textColor;
  final Color highlightColor;
  final int? maxLines;
  final TextAlign textAlign;
  final double height;

  const BybHighlightedText(
    this.text, {
    Key? key,
    this.fontSize = 16,
    this.textColor = Colors.black87,
    this.highlightColor = const Color(0x554A90D9), // Semi-transparent blue
    this.maxLines,
    this.textAlign = TextAlign.left,
    this.height = 1.2,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final upperText = text.toUpperCase();
    final spans = _buildSpans(upperText);

    return RichText(
      maxLines: maxLines,
      overflow: maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip,
      textAlign: textAlign,
      text: TextSpan(
        style: TextStyle(
          fontFamily: "BybHanddrawn",
          fontSize: fontSize,
          color: textColor,
          height: height,
        ),
        children: spans,
      ),
    );
  }

  List<TextSpan> _buildSpans(String input) {
    final List<TextSpan> result = [];
    int i = 0;

    while (i < input.length) {
      bool matched = false;

      for (final keyword in _highlightKeywords) {
        if (i + keyword.length <= input.length &&
            input.substring(i, i + keyword.length) == keyword) {
          // Check word boundary: keyword shouldn't be part of a larger word
          bool leftBoundary = (i == 0 || !_isLetterChar(input[i - 1]));
          bool rightBoundary = (i + keyword.length >= input.length ||
              !_isLetterChar(input[i + keyword.length]));

          if (leftBoundary && rightBoundary) {
            result.add(TextSpan(
              text: keyword,
              style: TextStyle(
                backgroundColor: highlightColor,
              ),
            ));
            i += keyword.length;
            matched = true;
            break;
          }
        }
      }

      if (!matched) {
        // Accumulate non-keyword characters
        int start = i;
        while (i < input.length) {
          bool isKeywordStart = false;
          for (final keyword in _highlightKeywords) {
            if (i + keyword.length <= input.length &&
                input.substring(i, i + keyword.length) == keyword) {
              bool leftBoundary = (i == 0 || !_isLetterChar(input[i - 1]));
              bool rightBoundary = (i + keyword.length >= input.length ||
                  !_isLetterChar(input[i + keyword.length]));
              if (leftBoundary && rightBoundary) {
                isKeywordStart = true;
                break;
              }
            }
          }
          if (isKeywordStart) break;
          i++;
        }
        result.add(TextSpan(text: input.substring(start, i)));
      }
    }

    return result;
  }

  static bool _isLetterChar(String ch) {
    final code = ch.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }
}
