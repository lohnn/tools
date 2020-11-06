import '../constants.dart';

class Commit {
  final String commit;
  final String abbrevatedCommit;
  final String tree;
  final String parent;
  final String abbrevatedParent;
  final String refs;
  final String subject;
  final String body;
  final Author author;
  final Author commiter;

  Commit._({
    this.commit,
    this.abbrevatedCommit,
    this.tree,
    this.parent,
    this.abbrevatedParent,
    this.refs,
    this.subject,
    this.body,
    this.author,
    this.commiter,
  });

  static Commit fromMap(Map<String, dynamic> map) {
    return Commit._(
      commit: map['commit'],
      abbrevatedCommit: map['abbreviated_commit'],
      tree: map['tree'],
      parent: map['parent'],
      abbrevatedParent: map['abbreviated_parent'],
      refs: map['refs'],
      subject: map['subject'],
      body: map['body'],
      author: Author(
        name: map['authorName'],
        email: map['authorEmail'],
        date: map['authorDate'],
      ),
      commiter: Author(
        name: map['committerName'],
        email: map['committerEmail'],
        date: map['committerDate'],
      ),
    );
  }

  String get ticketName => ticketRegexp.firstMatch(subject)?.group(0);

  @override
  String toString() {
    return subject;
  }
}

class Author {
  final String name;
  final String email;
  final String date;

  Author({this.name, this.email, this.date});
}
