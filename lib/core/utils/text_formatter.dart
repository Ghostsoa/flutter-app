import 'package:flutter/material.dart';

class TextFormatter {
  /// 格式化大模型响应文本
  /// 处理以下模式：
  /// - text[text]/【text】 -> text\n[text]\n
  /// - text(text)/（text）/（text) -> text\n(text)\n
  /// - [text](text)/【text】（text）/【text】(text) -> \n[text]\n(text)\n
  /// - [text]text/【text】text -> \n[text]\ntext
  /// - (text)text/（text）text -> \n(text)\ntext
  static String formatModelResponse(String text) {
    if (text.isEmpty) return text;

    final buffer = StringBuffer();
    int i = 0;

    while (i < text.length) {
      // 处理 [text] 或 【text】 模式
      if (i < text.length && (text[i] == '[' || text[i] == '【')) {
        if (buffer.isNotEmpty && buffer.toString().trimRight().isNotEmpty) {
          buffer.write('\n');
        }
        buffer.write('[');
        i++;

        // 寻找对应的 ] 或 】
        while (i < text.length && text[i] != ']' && text[i] != '】') {
          buffer.write(text[i]);
          i++;
        }
        if (i < text.length && (text[i] == ']' || text[i] == '】')) {
          buffer.write(']\n');
          i++;
        }
        continue;
      }

      // 处理 (text) 或 （text） 或 (text） 或 （text) 模式
      if (i < text.length && (text[i] == '(' || text[i] == '（')) {
        if (buffer.isNotEmpty && buffer.toString().trimRight().isNotEmpty) {
          buffer.write('\n');
        }
        buffer.write('(');
        i++;

        // 寻找对应的 ) 或 ）
        while (i < text.length && text[i] != ')' && text[i] != '）') {
          buffer.write(text[i]);
          i++;
        }
        if (i < text.length && (text[i] == ')' || text[i] == '）')) {
          buffer.write(')\n');
          i++;
        }
        continue;
      }

      // 处理普通文本
      buffer.write(text[i]);
      i++;
    }

    return buffer.toString().trim();
  }

  /// 将文本渲染为带有高亮效果的 TextSpan 列表
  /// [text] 要渲染的文本
  /// [textColor] 普通文本的颜色
  /// [quoteColor] 引号内容的高亮颜色（默认蓝色）
  /// [bracketColor] 括号内容的高亮颜色（默认橙色）
  /// [fontSize] 字体大小
  /// [height] 行高
  /// [letterSpacing] 字间距
  /// [fontWeight] 高亮文本的字重
  static List<TextSpan> formatHighlightText(
    String text, {
    required Color textColor,
    Color? quoteColor,
    Color? bracketColor,
    double fontSize = 15,
    double height = 1.5,
    double letterSpacing = 0.3,
    FontWeight fontWeight = FontWeight.w500,
  }) {
    final List<TextSpan> spans = [];
    int lastMatchEnd = 0;

    // 第一步：处理括号
    final bracketPattern = RegExp(r'([（(](.*?)[)）])', dotAll: true);
    final List<(int, int, String)> bracketTexts = [];

    for (final match in bracketPattern.allMatches(text)) {
      bracketTexts.add((
        match.start,
        match.end,
        match.group(1)! // 完整匹配（包含括号）
      ));
    }

    // 第二步：处理引号（可能包含括号）
    final quotePattern = RegExp(r'([“”](.*?)[“”])', dotAll: true);
    final List<(int, int, String)> quotedTexts = [];

    for (final match in quotePattern.allMatches(text)) {
      quotedTexts.add((
        match.start,
        match.end,
        match.group(1)! // 完整匹配（包含引号）
      ));
    }

    // 合并并排序所有匹配项
    final allMatches = [...quotedTexts, ...bracketTexts];
    allMatches.sort((a, b) => a.$1.compareTo(b.$1));

    // 构建 spans
    lastMatchEnd = 0;
    for (final match in allMatches) {
      // 添加匹配前的普通文本
      if (match.$1 > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.$1),
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            height: height,
            letterSpacing: letterSpacing,
          ),
        ));
      }

      // 判断是引号还是括号文本
      final isQuote = match.$3.startsWith('“') || match.$3.startsWith('”');

      // 如果是引号内容，需要检查是否包含括号并进行处理
      if (isQuote) {
        final innerText = match.$3;
        final innerBrackets = bracketPattern.allMatches(innerText);
        if (innerBrackets.isEmpty) {
          // 没有括号，整体显示为蓝色
          spans.add(TextSpan(
            text: match.$3,
            style: TextStyle(
              color: quoteColor ?? Colors.blue[300],
              fontSize: fontSize,
              height: height,
              letterSpacing: letterSpacing,
              fontWeight: fontWeight,
            ),
          ));
        } else {
          // 有括号，需要分段处理
          int innerLastEnd = 0;
          for (final bracket in innerBrackets) {
            // 添加括号前的文本（蓝色）
            if (bracket.start > innerLastEnd) {
              spans.add(TextSpan(
                text: innerText.substring(innerLastEnd, bracket.start),
                style: TextStyle(
                  color: quoteColor ?? Colors.blue[300],
                  fontSize: fontSize,
                  height: height,
                  letterSpacing: letterSpacing,
                  fontWeight: fontWeight,
                ),
              ));
            }

            // 添加括号部分（橙色）
            spans.add(TextSpan(
              text: bracket.group(1),
              style: TextStyle(
                color: bracketColor ?? Colors.orange[300],
                fontSize: fontSize,
                height: height,
                letterSpacing: letterSpacing,
                fontWeight: fontWeight,
              ),
            ));

            innerLastEnd = bracket.end;
          }

          // 添加最后一个括号后的文本（如果有）
          if (innerLastEnd < innerText.length) {
            spans.add(TextSpan(
              text: innerText.substring(innerLastEnd),
              style: TextStyle(
                color: quoteColor ?? Colors.blue[300],
                fontSize: fontSize,
                height: height,
                letterSpacing: letterSpacing,
                fontWeight: fontWeight,
              ),
            ));
          }
        }
      } else {
        // 括号文本直接显示为橙色
        spans.add(TextSpan(
          text: match.$3,
          style: TextStyle(
            color: bracketColor ?? Colors.orange[300],
            fontSize: fontSize,
            height: height,
            letterSpacing: letterSpacing,
            fontWeight: fontWeight,
          ),
        ));
      }

      lastMatchEnd = match.$2;
    }

    // 添加最后一段文本
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          height: height,
          letterSpacing: letterSpacing,
        ),
      ));
    }

    return spans;
  }
}
