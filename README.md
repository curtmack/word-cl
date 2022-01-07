# Word-CL

A terminal-based clone of [Wordle](https://www.powerlanguage.co.uk/wordle/)
by [Josh Wardle](https://twitter.com/powerlanguish).

## Usage

Load `word-cl.lisp` in your Lisp implementation and run `(word-cl:main)`.

This needs a word list file; the default behavior is to look in the
current directory for a file named `popular.txt`.  (The standard
`/usr/share/dict/words` file on Unix-like systems is far too
verbose for an enjoyable word game.)  That file can be found at
[dolph/dictionary](https://github.com/dolph/dictionary/), but unfortunately
it's not licensed, so I can't use it

## Compatibility Notes

The code should work (with some modifications - I don't understand logical
pathnames yet) on any operating system.  There are a few "non-portable"
assumptions, but any operating system with a terminal that supports standard
ANSI escape codes should work.  There are no dependencies outside the Common
Lisp standard.

`make word-cl` creates a standalone executable.  Currently, this only works
in SBCL.  Tested in SBCL 2.0.1 on Fedora 34.

