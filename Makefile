### Copyright 2022 Curtis Mackie <curtis@mackie.ninja>
### SPDX-Short-Identifier: Apache-2.0

SBCL_ARGS = --no-sysinit --no-userinit --disable-debugger
SBCL_LOAD = --load word-cl.lisp
SBCL_SLAD = --eval "(sb-ext:save-lisp-and-die \"word-cl\" :executable t :toplevel 'word-cl:main)"

word-cl: word-cl.lisp
	sbcl $(SBCL_ARGS) $(SBCL_LOAD) $(SBCL_SLAD)
