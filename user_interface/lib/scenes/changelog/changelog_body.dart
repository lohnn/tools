import '../changelog/changelog_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/all.dart';
import 'package:searchable_dropdown/searchable_dropdown.dart';

class ChangelogBody extends ConsumerWidget {
  @override
  Widget build(BuildContext context, ScopedReader watch) {
    final remoteBranches = watch(branchesProvider);
    final dir = watch(currentRepoDirectoryProvider).state;
    if (remoteBranches == null || remoteBranches.isEmpty) return Container();
    return Row(
      key: Key(dir.directory),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: SearchableDropdown<String>.single(
            items: remoteBranches.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            // value: selectedValue,
            hint: 'master',
            searchHint: null,
            onChanged: (value) {
              context.read(leftBranchProvider).state = value;
            },
            dialogBox: false,
            isExpanded: true,
            menuConstraints: BoxConstraints.tight(Size.fromHeight(350)),
          ),
        ),
        Expanded(
          child: SearchableDropdown<String>.single(
            items: remoteBranches.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            // value: selectedValue,
            hint: 'master',
            searchHint: null,
            onChanged: (value) {
              context.read(rightBranchProvider).state = value;
            },
            isExpanded: true,
            dialogBox: false,
            menuConstraints: BoxConstraints.tight(Size.fromHeight(350)),
          ),
        ),
      ],
    );
  }
}
