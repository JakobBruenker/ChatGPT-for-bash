ChatGPT for Bash
================

This repository provides a script which allows you to send natural language
descriptions to ChatGPT, and have it generate bash (or zsh) commands for you.

Example:

```bash
user@pc:~> _ show me my commits since the beginning of this month
I think I can do that with the following command:

  git log --author="$(git config user.name)" --since="$(date +%Y-%m-01)"

Sound good? (Enter to accept, Ctrl-C to cancel, or just write more to refine your request)
> actually do since the beginning of this week
I think I can do that with the following command:

  git log --author="$(git config user.name)" --since="$(date +%Y-%m-%d -d 'last monday')"

Sound good? (Enter to accept, Ctrl-C to cancel, or just write more to refine your request)
```

If you confirm by pressing enter, the command will be run.

Usage
-----

The recommended usage is putting the following function in your `.bashrc`,
`.bash_profile`, or `.zshrc`:

```bash
function _ { source <path_to_repo>/chatgpt_for_bash.sh; }
```

Where `<path_to_repo>` is the path to the directory containing this file.

Why `_`? Because it's the only non-alphanumeric character that doesn't have
another function in bash, and thus won't interfere with anything. You are of
course free to choose any other name.

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
You will also need `bash` or `zsh`, as well as `jq`, which is used to parse
ChatGPT's JSON response. Your package manager should be able to provide it.
