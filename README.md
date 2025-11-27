# Competing standards

This repo includes

- Definition of the ad-hoc VM for sfi20 CTF (spec.md)
- An assembler for this VM (asm.el)
- An implementation of this VM (vm.scm)

Read the [blog post](https://krzysckh.org/b/Virtual-mischief.html).

## Using the assembler

The assembler is written in emacs lisp (bold choice) and the syntax is fairly simple.
It's a 1.5 pass assembler (would be a strong choice of words to call it a 2-pass assembler as it only does *some* "backtracking").

Functions/variables declared by the assembler are prefixed with `A/` and `A//`.

### Compiling stuff

if you name your file `file.el`, and declare `A//file` variable with your code in it, you can use `make file.bin` to compile it (assuming emacs with `dash` and `f` is installed)

otherwise, you can:

- Open `asm.el`: `C-x C-f asm.el RET`
- Load functions from `asm.el`: `M-x eval-buffer RET`
- Compile a basic program `M-: (A/compile A//hello-world "hello.bin")`

### Syntax

A program will start at the keyword `:_start`, the assembler allows for simple subroutine definitions.
Subroutine definitions have local scope for identifiers.

this program for example will never halt, as sub-local `:recur` takes priority over global `:recur`.
```elisp
(defconst A//example
  `(:recur
    (define oops!
      (& div 0 0))
    (define sub
      :recur
        (goto :recur))
    :_start
      (call sub)))
```

`goto`, `call` and `push` are the only ops that are handled specially.
they accept args like they would be normal functions and get later compiled to pushes and calls.

#### Macros

- the `(& op arg ...)` macro can be only used inside a subroutine. it pushes `arg ...` before calling `op`.

- `(-> addr n)` pushes n bytes `[addr, addr+1, ..., addr+n]` to the stack. WARNING: 0 for `->` is actually the start of `A/dyn-memory`, so it's actually `addr+0x6`

- `(<- addr arg ...)` pushes `arg ...` to `[addr, addr+1, ..., addr+n]` (same warning as above)

- `(<-S addr n)` pushes `n` values from stack to `[addr, addr+1, ..., addr+n]`. (same warning as above)

## Using the vm

this vm implementation is written in [owl lisp](https://gitlab.com/owl-lisp/owl).
usage:

```sh
$ ol -r vm.scm file.bin
```
