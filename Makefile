### Copyright 2022 Curtis Mackie <curtis@mackie.ninja>
### SPDX-Short-Identifier: Apache-2.0

COMPRESSION_LEVEL ?= 9

SBCL_ARGS = --no-sysinit --no-userinit --disable-debugger
SBCL_LOAD = --load word-cl.lisp
SBCL_SLAD = --eval "(sb-ext:save-lisp-and-die \"word-cl\" :executable t :compression $(COMPRESSION_LEVEL) :toplevel 'word-cl:main)"

# include Makefile as a dependent, as the arguments above might change
word-cl: Makefile word-cl.lisp
	sbcl $(SBCL_ARGS) $(SBCL_LOAD) $(SBCL_SLAD)
