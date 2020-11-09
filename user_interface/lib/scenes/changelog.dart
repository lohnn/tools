import 'dart:io';

import 'package:file_chooser/file_chooser.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:hooks_riverpod/all.dart';
import 'package:url_launcher/url_launcher.dart';

import 'changelog/changelog_body.dart';
import 'changelog/changelog_state_provider.dart';

class Changelog extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final folderPathController = useTextEditingController();
    final folderPathFocusNode = useFocusNode();
    return GestureDetector(
      //Deselect text fields when clicking outside them
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Git changelog'),
        ),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProviderListener<StateController<GitDirectory>>(
                provider: currentRepoDirectoryProvider,
                onChange: (context, value) {
                  folderPathController.value = folderPathController.value
                      .copyWith(text: value.state.directory);
                  if (value.state.isGitRepo) folderPathFocusNode.unfocus();
                },
                child: CupertinoTextField(
                  focusNode: folderPathFocusNode,
                  controller: folderPathController,
                  placeholder: 'Directory',
                  onChanged: (value) {
                    context
                        .read(changelogViewController)
                        .onUpdateDirectoryField(value);
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
              ),
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
              BaseUrl(),
            ],
          ),
        ),
      ),
    );
  }
}

class BaseUrl extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final isGitRepo = useProvider(currentRepoDirectoryProvider).state.isGitRepo;
    final controller = useTextEditingController();
    if (!isGitRepo) return Container();
    return ProviderListener(
      provider: baseUrlProvider,
      onChange: (BuildContext context, String value) {
        controller.value = controller.value.copyWith(text: value);
      },
      child: CupertinoTextField(
        placeholder:
            'Project base url (e.g. https://myproject.jira.com/browse/)',
        controller: controller,
        onChanged: (value) {
          context.read(changelogViewController).onUpdateBaseUrlField(value);
        },
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
