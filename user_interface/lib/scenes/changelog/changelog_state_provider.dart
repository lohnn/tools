import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tools/git/changelog/changelog_fetcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

final changelogViewController =
    Provider.autoDispose((ref) => ChangelogViewController(ref.read));

class ChangelogViewController {
  final Reader read;

  ChangelogViewController(this.read);

  void onUpdateTextField(String dir) {
    var isGit = Directory('$dir/.git').existsSync();
    read(currentRepoDirectoryProvider).state = GitDirectory(dir, isGit);
    if (isGit) {
      read(_savedRepositoriesProvider).saveDirectory(dir);
    }
  }

  void selectDirectory(String dir) {
    if (read(currentRepoDirectoryProvider).state.directory != dir) {
      onUpdateTextField(dir);
    }
  }

  void removeDirectory(String dir) {
    read(_savedRepositoriesProvider).removeDirectory(dir);
  }
}

final currentRepoDirectoryProvider = StateProvider<GitDirectory>((ref) {
  return GitDirectory('', false);
});

class GitDirectory {
  final String directory;
  final bool isGitRepo;

  GitDirectory(this.directory, this.isGitRepo);
}

final _gitFetchProvider = FutureProvider<dynamic>((ref) async {
  final gitDir = ref.watch(currentRepoDirectoryProvider).state;
  if (!gitDir.isGitRepo) return;

  await Process.run(
    'git',
    [
      'fetch',
    ],
    workingDirectory: gitDir.directory,
  );
  print('Git fetch done');
  return;
});

final branchesProvider = Provider<List<String>>((ref) {
  //Has directory a Git repository
  ref.watch(_gitFetchProvider);
  final gitDir = ref.watch(currentRepoDirectoryProvider).state;
  if (!gitDir.isGitRepo) {
    return null;
  }

  final currentDirectory =
      ref.read(currentRepoDirectoryProvider).state.directory;
  final temp = Process.runSync(
    'git',
    [
      'branch',
      '-r',
    ],
    workingDirectory: currentDirectory,
  );
  final branches =
      (temp.stdout as String).split('\n').map((e) => e.trim()).toList();
  return branches;
});

final leftBranchProvider = StateProvider<String>((ref) {
  ref.watch(currentRepoDirectoryProvider);
  return null;
});
final rightBranchProvider = StateProvider<String>((ref) {
  ref.watch(currentRepoDirectoryProvider);
  return null;
});

List<String> _getChangelog(
  String fromBranch,
  String toBranch,
  String workingDirectory,
) {
  if (workingDirectory.isEmpty) return [];
  return ChangelogFetcher.getChangelog(
    fromBranch,
    toBranch,
    workingDirectory: workingDirectory,
  )
      .map((e) => e.ticketName?.toUpperCase())
      .toSet()
      .where((element) => element != null)
      .toList();
}

final _trackingMasterBranch = Provider<String>((ref) {
  final dir = ref.watch(currentRepoDirectoryProvider).state;
  if (dir.isGitRepo) {
    try {
      return (Process.runSync(
        'git',
        [
          'rev-parse',
          '--abbrev-ref',
          'master@{upstream}',
        ],
        workingDirectory: dir.directory,
      ).stdout as String)
          .trim();
    } catch (_) {
      return 'master';
    }
  }
  return 'master';
});

final changelog = Provider<Changelog>((ref) {
  ref.watch(_gitFetchProvider);
  final trackingMaster = ref.watch(_trackingMasterBranch);
  final leftBranch = ref.watch(rightBranchProvider).state ?? trackingMaster;
  final rightBranch = ref.watch(leftBranchProvider).state ?? trackingMaster;
  final gitRepo = ref.watch(currentRepoDirectoryProvider).state;
  if (!gitRepo.isGitRepo) return Changelog.empty;
  return Changelog.withData(
    _getChangelog(leftBranch, rightBranch, gitRepo.directory),
    _getChangelog(rightBranch, leftBranch, gitRepo.directory),
  );
});

class Changelog {
  final List<Change> left;
  final List<Change> right;

  const Changelog._({
    @required this.left,
    @required this.right,
  })  : assert(left != null),
        assert(right != null);

  factory Changelog.withData(List<String> left, List<String> right) {
    final newLeft = left.map((e) => Change(e, right.contains(e))).toList()
      ..sortChange();
    final newRight = right.map((e) => Change(e, left.contains(e))).toList()
      ..sortChange();
    return Changelog._(
      left: newLeft,
      right: newRight,
    );
  }

  static const empty = Changelog._(
    left: [],
    right: [],
  );
}

class Change {
  final String ticketName;
  final bool existsInBoth;

  Change(this.ticketName, this.existsInBoth);

  //TODO: Change to support update from UI (and saving between usages)
  String get url => 'https://myproject.jira.com/browse/$ticketName';
}

final _sharedPreferencesClient = Provider((ref) => _SharedPreferencesClient());

class _SharedPreferencesClient {
  Future<List<String>> getList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  Future<void> saveList(String key, List<String> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, list);
  }
}

final _savedRepositoriesProvider =
    StateNotifierProvider<_SavedRepositories>((ref) {
  return _SavedRepositories(ref.read);
});

class _SavedRepositories extends StateNotifier<Set<String>> {
  Reader read;

  _SavedRepositories(this.read) : super({}) {
    loadFromPrefs();
  }

  Future loadFromPrefs() async {
    state =
        (await read(_sharedPreferencesClient).getList('saved_reps'))?.toSet() ??
            {};
  }

  void saveDirectory(String directory) {
    state = {
      ...state,
      directory,
    };
    read(_sharedPreferencesClient).saveList('saved_reps', state.toList());
  }

  void removeDirectory(String directory) {
    state = state.toSet()..remove(directory);
    read(_sharedPreferencesClient).saveList('saved_reps', state.toList());
  }
}

final previousRepositoriesProvider = Provider<Iterable<String>>((ref) {
  return ref.watch(_savedRepositoriesProvider.state);
});

extension on List<Change> {
  void sortChange() {
    sort((a, b) {
      final firstSort = a.existsInBoth.compareTo(b.existsInBoth);
      if (firstSort != 0) return firstSort;
      return a.ticketName.compareTo(b.ticketName);
    });
  }
}

extension on bool {
  int compareTo(bool other) {
    if (this == other) return 0;
    if (other) return 1;
    return -1;
  }
}
