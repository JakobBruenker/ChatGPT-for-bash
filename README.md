ChatGPT for Bash
================

This repository provides a script which allows you to send natural language
descriptions to ChatGPT, and have it generate bash commands for you.

Example:

```
user@pc:~> ? show the last ten commits by me
I think I can do that with this command:

  git log --author="$(git config user.name)" -n 10

Sound good? [Y/n]
```

If you confirm by pressing enter, the command will be run.

Usage
-----

The recommended usage is putting the following function in your `.bashrc` or `.bash_profile`:

```bash
function ? { source chatgpt_for_bash.sh; }
```

This requires that `chatgpt_for_bash.sh` is in your path; otherwise you can use the full path.

> **Note**
> if you run the script directly rather than via `source`, some features won't
> work, like adding the generated commands to your history and changing
> directories.

Requirements
------------

You will need to provide your OpenAI API key via
```
export OPENAI_API_KEY=<your_api_key>
```
You will also need `bash`, as well as `jq`, which is used to parse ChatGPT's
JSON response. Your package manager should be able to provide it.

You will probably also want put the `$` script into a directory that is in
your `$PATH`.
