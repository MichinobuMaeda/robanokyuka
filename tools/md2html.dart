import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:markdown/markdown.dart' as md;
import 'md2html_template.dart';

final inputPath = 'docs';
final outputPath = p.join('build', 'web', 'docs');
final assetPath = 'assets';

void main() {
  final inputDir = Directory(inputPath);
  if (!inputDir.existsSync()) {
    stderr.writeln('Error: $inputPath directory not found.');
    exitCode = 1;
    return;
  }

  final outputDir = Directory(outputPath);
  if (!outputDir.existsSync()) {
    outputDir.createSync(recursive: true);
  }

  // Copy CSS file
  try {
    final cssSource = File(p.join('tools', 'md2html.css'));
    if (!cssSource.existsSync()) {
      stderr.writeln('Error: tools/md2html.css not found.');
      exitCode = 1;
      return;
    }
    final cssDest = File(p.join(outputPath, 'main.css'));
    cssSource.copySync(cssDest.path);
    stdout.writeln('Copied: ${cssDest.path}');
  } catch (e) {
    stderr.writeln('Error copying CSS file: $e');
    exitCode = 1;
    return;
  }

  // Copy non-Markdown files from inputPath to outputPath
  final nonMdFiles = inputDir
      .listSync()
      .whereType<File>()
      .where((f) => !f.path.endsWith('.md'))
      .toList();

  for (final file in nonMdFiles) {
    try {
      final destPath = p.join(outputPath, file.uri.pathSegments.last);
      file.copySync(destPath);
      stdout.writeln('Copied: $destPath');
    } catch (e) {
      stderr.writeln('Error copying ${file.path}: $e');
      exitCode = 1;
    }
  }

  // Process Markdown files
  final mdFiles = inputDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList();

  if (mdFiles.isEmpty) {
    stderr.writeln('No Markdown files found in docs directory.');
    exitCode = 1;
    return;
  }

  for (final file in mdFiles) {
    try {
      var markdown = file.readAsStringSync();
      // Replace .md links with .html
      markdown = markdown.replaceAll(RegExp(r'\.md(?=[\)\]])'), '.html');
      final html = md.markdownToHtml(
        markdown,
        blockSyntaxes: [const md.TableSyntax()],
      );
      final htmlFileName = file.uri.pathSegments.last.replaceAll(
        '.md',
        '.html',
      );
      final htmlPath = p.join(outputPath, htmlFileName);
      final htmlContent = template(file.uri.pathSegments.last, html);
      File(htmlPath).writeAsStringSync(htmlContent);
      stdout.writeln('Generated: $htmlPath');
    } catch (e) {
      stderr.writeln('Error processing ${file.path}: $e');
      exitCode = 1;
    }
  }

  // Copy info.md to assets and replace links
  try {
    final infoSource = File(p.join(inputPath, 'info.md'));
    if (infoSource.existsSync()) {
      var infoMarkdown = infoSource.readAsStringSync();
      // Remove level 1 headings
      infoMarkdown = infoMarkdown.replaceAll(
        RegExp(r'^# .+\n?', multiLine: true),
        '',
      );
      // Replace local index.md link with external URL
      infoMarkdown = infoMarkdown.replaceAll(
        RegExp(r'./index\.md'),
        'https://robanokyuka.firebaseapp.com/docs/index.html',
      );
      final infoDest = File(p.join(assetPath, 'info.md'));
      infoDest.writeAsStringSync(infoMarkdown);
      stdout.writeln('Copied and processed: ${infoDest.path}');
    }
  } catch (e) {
    stderr.writeln('Error processing info.md: $e');
    exitCode = 1;
  }

  stdout.writeln('✓ All Markdown files converted to HTML');
}
