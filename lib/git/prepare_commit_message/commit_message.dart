#!/usr/bin/env dart

import 'dart:io';

import '../constants.dart';

main(List<String> args) async {
  final commitMessageFileName = args[0];
  final branchName = await getBranchName();

  print('Arguments: ${args}');
  print('Commit message file: $commitMessageFileName');
  print('Branchname: $branchName');

  if (branchName != null && branchName.isNotEmpty) {
    final description = getDescription(branchName);
    print('Description: $description');
    print('Description is empty? ${description?.isEmpty}');

    final file = File(commitMessageFileName);
    final fileContent = await file.readAsString();

    //Make sure we don't write branch name again if message
    //already starts with it
    if (fileContent.startsWith(ticketRegexp)) {
      return 0;
    }

    await appendToFile(file, '$branchName: ');

    if (description != null && description.isNotEmpty) {
      await prependToFile(file, description);
    }
  }
}

/// Gets branch name of current catalog
Future<String> getBranchName() async {
  String gitBranches = Process.runSync('git', ['branch']).stdout;

  final branchWithStarProcess = await Process.start('grep', ['*']);
  branchWithStarProcess.stdin.write(gitBranches);
  await branchWithStarProcess.stdin.close();

  final branchWithStar = await branchWithStarProcess.stdout.single
      .then((array) => String.fromCharCodes(array));

  final branches = ticketRegexp.firstMatch(branchWithStar);
  if (branches == null) {
    return null;
  } else {
    return branches.group(0);
  }
}

String getDescription(String branchName) {
  return Process.runSync('git', ['config', 'branch.$branchName.description'])
      .stdout;
}

Future appendToFile(File file, String textToAppend) async {
  print("Appending '$textToAppend' to file ${file.path}");
  final content = await file.readAsString();
  final newContent = textToAppend + content;
  await file.writeAsString(newContent);
}

Future prependToFile(File file, String textToPrepend) async {
  print("Prepending '$textToPrepend' to file ${file.path}");
  final content = await file.readAsString();
  final newContent = content + textToPrepend;
  await file.writeAsString(newContent);
}
