# Introduction #

This document describes our subversion commit policy.

# Details #

  * Code committed to the repository **must** compile, and it must not crash the game, as these will prevent others from doing their work.  It is OK if it doesn't quite work or if it is buggy, but it must at least compile and run without massive errors.
  * New code must follow our coding standards. Old code that you modify should be brought up to our coding standards.
  * New code must be documented.  Existing code that you modify should be documented or have its documentation updated to our standards.
  * Only source code should be committed, not generated files.
  * Before you commit changes, create a diff (TortoiseSVN: create patch) and review it so you know exactly what you are committing.
  * Try to keep your commits atomic--everything related to a new feature should be committed at the same time.
  * Use a meaningful commit message to describe the changes you have made.
  * Don't commit changes to someone else's code without talking to them first to make sure you are both on the same page.
  * Do not get into commit wars.