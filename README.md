Some nice scripts to streamline your life
================

This project contains some small scripts to improve quality of life.

The scripts are written in Dart, as this is a strongly typed language that allows for quick
prototyping as well as compilation to native binaries, removing the requirement of Dart being installed
on the machine, if desired.

Git changelog script
--------------------
### Functionality of changelog script
This script is used to create a changelog list of tickets that are added
since an older version of the app, or between two branches (versions).
Provided your tickets follow the naming convention of PROJECT-1234.

### Usage of changelog script
First of all, make sure your repo has fetched all changes and is up to
date and that your terminal is currently working in the repo folder.

> $ dart PATH_TO_SCRIPTS/lib/git/changelog/main.dart old_branch [new_branch]

First argument (old_branch) is required, this is the branch of the
version of the app you are checking against.

Second argument is optional and will fall back to `master` which is the
tip of the master branch, so again, make sure to fetch all changes
before running this script to get the actual changes.

For more help on how to use the script, run
> $ dart PATH_TO_SCRIPTS/lib/git/changelog/main.dart --help

#####  PRO TIP: git commit hashes also works as arguments.
Example:

> $ dart PATH_TO_SCRIPTS/lib/changelog/main.dart b68894ad8 ef8ed97f8

This will show the changelog between commits b68894ad8 and ef8ed97f8.

##### Noteworthy

This script will find all commits that somewhere in the description
includes something that follows the structure of a ticket id
(`[a-zA-Z]+-[0-9]+`) and not just the ones
that _starts_ with it.  
Example ticket description that might not be correct:

> This is a ticket description with text and a dash with digit-42

This would confuse the script and think that `digit-42` is a ticket id,
which it is not. So you might need to take a look at the outcome just to
make sure there is no such occurrences.

Prepare commit message script
-----------------------------
### Functionality of commit preparation script
This script will prefix all your commits with ticket name if the current
branch starts with `[a-zA-Z]+-[0-9]+` following the branch names.

### Preparation of commit preparation script

> $ dart2native PATH_TO_SCRIPTS/lib/prepare_commit_message/commit_message.dart -o commit-msg

This will create a file called commit-msg in the current location. Move
this file to your Git project to the path: `PATH_TO_PROJECT/.git/hooks/commit-msg`
