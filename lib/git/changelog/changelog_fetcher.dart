import 'dart:io';

import 'commit.dart';

class ChangelogFetcher {
  static const _separator = '=========';
  static const _lineEnding = '---------';
  static const _format = 'commit:%H$_lineEnding'
      'abbreviated_commit:%h$_lineEnding'
      'tree:%T$_lineEnding'
      'abbreviated_tree:%t$_lineEnding'
      'parent:%P$_lineEnding'
      'abbreviated_parent:%p$_lineEnding'
      'refs:%D$_lineEnding'
      'encoding:%e$_lineEnding'
      'subject:%s$_lineEnding'
      'sanitized_subject_line:%f$_lineEnding'
      'body:%b$_lineEnding'
      'commit_notes:$_lineEnding'
      'verification_flag:%G?$_lineEnding'
      'signer:%GS$_lineEnding'
      'signer_key:%GK$_lineEnding'
      'authorName:%aN$_lineEnding'
      'authorEmail:%aE$_lineEnding'
      'authorDate:%aD'
      'committerName:%cN$_lineEnding'
      'committerEmail:%cE$_lineEnding'
      'committerDate:%cD$_lineEnding'
      '$_separator';

  static Iterable<Commit> getChangelog(String fromBranch, String toBranch,
      {String workingDirectory}) {
    final result = Process.runSync(
      'git',
      [
        'log',
        '--pretty=format:$_format',
        '$fromBranch..$toBranch',
      ],
      workingDirectory: workingDirectory,
    ).stdout as String;

    if (result.isEmpty) {
      return [];
    }

    final split = result.split(_separator);

    final mapIterable = _mapChangelog(split);
    return mapIterable.map((element) => Commit.fromMap(element));
  }

  static Iterable<Map<String, String>> _mapChangelog(
      Iterable<String> resultString) {
    return resultString
        .map<Map<String, String>>(
          (e) => Map.fromEntries(
            e
                .split(_lineEnding)
                .map((e) => e.extractMapEntry())
                .where((element) => element != _StringExtension.EMPTY),
          ),
        )
        .where((element) => element.isNotEmpty);
  }
}

extension _StringExtension on String {
  static final MapEntry<String, String> EMPTY = MapEntry('EMPTY', 'EMPTY');

  MapEntry<String, String> extractMapEntry() {
    if (trim().isEmpty) {
      return EMPTY;
    }

    final separatorIndex = indexOf(':');
    final key = substring(0, separatorIndex).trim();
    final value = substring(separatorIndex + 1).trim();
    return MapEntry(key, value);
  }
}
