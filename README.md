# lcrename

A utility for renaming files to their lowercase form on MacOS, even on case-insensitive filesystems.

Supports files passed as arguments or from standard input, either as absolute or relative paths.

## Installation

### Prerequisites

- macOS 10.15 (Catalina) or later
- Xcode and the Command Line Tools installed

### From source

Clone the repository and navigate to the project directory:

```sh
git clone https://github.com/inopinatus/lcrename.git
cd lcrename
```

Compile and install:

```sh
make install
```

Now, you should be able to use `lcrename` from anywhere in your terminal. By default, files will be installed under `/usr/local`. You can adjust locations using the variables in the Makefile, e.g. `make install PREFIX=/opt`.

## Usage

```
lcrename [-v] [-0] [--] [files...]
  -v: Verbose output
  -0: Expect NUL (`\0`)-terminated filename strings on stdin
  --: End of options processing; all subsequent arguments are files
```

File paths may be passed as arguments, or from standard input, but not both.  Either absolute and relative paths may be given.  Relative paths will be resolved from the current working directory.  Filenames must be an exact match for their current capitalisation.

Files that do not exist, or for which a conflicting file with a lower-case name already exists, will be skipped with a warning.

## Examples

1. Rename all TXT files in current directory to use lowercase:

```sh
lcrename *.TXT
```

2. Find and rename potentially many files scattered about:

```sh
find ~/Documents/*.txt -print0 | lcrename -0
```

3. Rename a file supplied from user input:

```sh
read -p 'file: ' FILENAME
lcrename -- "$FILENAME"
```

## Motivation

On case-insensitive filesystems (including the default AFPS format), using mv(1) to rename a file whilst only changing its case can fail.

## Contributing

Bug reports and pull requests are welcome on Github at https://github.com/inopinatus/lcrename
