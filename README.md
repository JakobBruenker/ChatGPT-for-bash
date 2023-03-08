ChatGPT for Bash
================

This repository provides a script called `$`, which allows you to send natural
language descriptions to ChatGPT, and have it generate bash commands for you.

Example:

```
user@pc:~> $ show the last ten commits by me
I think I can show the last ten commits by me with this command:

  git log --author="$(git config user.name)" -n 10

Sound good? [Y/n] 
```

If you confirm by pressing enter, the command will be run.

Requirements
------------

You will need to provide your OpenAI API key via
```
export OPENAI_API_KEY=<your_api_key>
```
You will also need `bash`, as well as `jq`, which is used to parse ChatGPT's
JSON response. Your package manager should be able to provide it.

You will probably also put the `$` script into a directory that is in your
`$PATH`.
