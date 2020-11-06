import 'dart:io';

import 'package:args/args.dart';

import 'changelog_fetcher.dart';

void main(List<String> args) async {
  final parser = ArgParser();
  parser.addOption(
    'urlBase',
    abbr: 'u',
    help:
        'Ticket base url, such as "https://myproject.jira.com/browse/" to create a ticket url looking like "https://myproject.jira.com/browse/TICKET-1234"',
  );
  parser.addFlag('help');
  final result = parser.parse(args);

  if(result['help']) {
    print('Sorry, no help added yet...');
    exit(0);
  }

  if (result.rest.isEmpty) {
    print(
      'You must at least declare a from-branch.',
    );
    exit(1);
  }

  final ticketUrlBase = result['urlBase'];

  final fromBranch = result.rest.first;
  final toBranch = result.rest.getOrDefault(1, 'master');

  final resultForward = ChangelogFetcher.getChangelog(fromBranch, toBranch);
  final resultBackwards = ChangelogFetcher.getChangelog(toBranch, fromBranch);

  final ticketNameSetForward = resultForward.map((e) => e.ticketName).toSet();
  final ticketNameSetBackwards =
      resultBackwards.map((e) => e.ticketName).toSet();

  final uniqueTickets = ticketNameSetForward
      .where(
        (element) =>
            element != null && !ticketNameSetBackwards.contains(element),
      )
      .toList();

  if (resultForward.isEmpty) {
    print('No changes between branch $fromBranch and $toBranch');
  } else {
    final ticketNameSet = uniqueTickets.map((e) {
      if (ticketUrlBase == null) return e;
      return '$e: $ticketUrlBase$e';
    });

    print('New tickets between $fromBranch and $toBranch:');
    ticketNameSet.forEach((element) => print(element));
  }
}

extension<T> on List<T> {
  T getOrDefault(int index, [T fallback]) {
    if (length > index) {
      return this[index];
    }
    return fallback;
  }
}
