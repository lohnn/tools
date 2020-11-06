import 'dart:io';

import 'package:file_chooser/file_chooser.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:url_launcher/url_launcher.dart';

import 'changelog/changelog_body.dart';
import 'changelog/changelog_state_provider.dart';

class Changelog extends StatefulWidget {
  @override
  _ChangelogState createState() => _ChangelogState();
}

class _ChangelogState extends State<Changelog> {
  TextEditingController _folderPathController;
  FocusNode _folderPathFocusNode;

  @override
  void initState() {
    super.initState();
    _folderPathController = TextEditingController();
    _folderPathFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _folderPathController.dispose();
    _folderPathFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Git changelog'),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Consumer(builder: (context, watch, child) {
              return ProviderListener<StateController<GitDirectory>>(
                provider: currentRepoDirectoryProvider,
                onChange: (context, value) {
                  _folderPathController.value = _folderPathController.value
                      .copyWith(text: value.state.directory);
                  if (value.state.isGitRepo) _folderPathFocusNode.unfocus();
                },
                child: CupertinoTextField(
                  focusNode: _folderPathFocusNode,
                  controller: _folderPathController,
                  placeholder: 'Directory',
                  onChanged: (value) {
                    context
                        .read(changelogViewController)
                        .onUpdateTextField(value);
                  },
                  suffix: CupertinoButton(
                    onPressed: () async {
                      final selection = await showOpenPanel(
                        canSelectDirectories: true,
                      );
                      if (selection.canceled || selection.paths.isEmpty) return;
                      final path = selection.paths.first;
                      if (await FileSystemEntity.isDirectory(path)) {
                        context
                            .read(changelogViewController)
                            .selectDirectory(path);
                        return;
                      }
                      context
                          .read(changelogViewController)
                          .selectDirectory(File(path).parent.path);
                    },
                    child: Icon(CupertinoIcons.folder_open),
                  ),
                ),
              );
            }),
            PreviousRepositories(),
            ChangelogBody(),
            Expanded(
              child: Consumer(
                builder: (context, watch, child) {
                  final changes = watch(changelog);
                  final isGitRepo =
                      watch(currentRepoDirectoryProvider).state.isGitRepo;
                  if (!isGitRepo) return Container();
                  return Row(
                    children: [
                      Expanded(
                        child: TicketList(changes.left),
                      ),
                      Expanded(
                        child: TicketList(changes.right),
                      )
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TicketList extends StatelessWidget {
  final List<Change> changes;

  TicketList(this.changes);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text(
            changes.length.toString(),
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w200,
            ),
          ),
        ),
        Expanded(
          child: Scrollbar(
            child: ListView.builder(
              itemCount: changes.length,
              itemBuilder: (context, index) => InkWell(
                onTap: () async {
                  var url = changes[index].url;
                  if (await canLaunch(url)) {
                    await launch(url);
                  } else {
                    await showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: Text('Could not open link'),
                          actions: [
                            CupertinoDialogAction(
                              child: Text('Ok'),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 8,
                  ),
                  child: Text(
                    changes[index].ticketName,
                    style: TextStyle(
                      color: changes[index].existsInBoth ? Colors.orange : null,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PreviousRepositories extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final previousDirectories = watch(previousRepositoriesProvider);
    return Column(
      children: previousDirectories
          .map(
            (e) => Row(
              children: [
                CupertinoButton(
                  onPressed: () {
                    context.read(changelogViewController).selectDirectory(e);
                  },
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color: Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                    child: Text(e),
                  ),
                ),
                Expanded(
                  child: Container(),
                ),
                CupertinoButton(
                  onPressed: () {
                    context.read(changelogViewController).removeDirectory(e);
                  },
                  child: Icon(CupertinoIcons.delete),
                ),
              ],
            ),
          )
          .toList(),
    );
  }
}
