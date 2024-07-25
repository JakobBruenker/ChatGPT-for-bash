#!/usr/bin/env bash

function move_cursor_up {
  if command -v tput >/dev/null 2>&1; then
    tput cuu1 >&2
  fi
}

function bold_start {
  printf "\033[1m\033[10m" >&2
}

function bold_end {
  printf "\033[0m" >&2
}

function check_command_input {
  echo -E "Sound good? (Enter to accept, Ctrl-C to cancel, or just write more to refine your request)" >&2
  read -r __chatgpt_for_bash_input
  if [[ -z "$__chatgpt_for_bash_input" ]]; then
    move_cursor_up
    if [[ -z "$ZSH_VERSION" ]]; then
      history -s "$__chatgpt_for_bash_command"
    else
      print -s "$__chatgpt_for_bash_command"
    fi
    eval "$__chatgpt_for_bash_command"
  else
    __chatgpt_for_bash_chat_hist+=("$__chatgpt_for_bash_question" "$__chatgpt_for_bash_response")
    __chatgpt_for_bash_question="$__chatgpt_for_bash_input"
    generate_command
  fi
}

function generate_command {
  __chatgpt_for_bash_json_chat_hist=()
  for ((__chatgpt_for_bash_i=0; __chatgpt_for_bash_i<${#__chatgpt_for_bash_chat_hist[@]}; __chatgpt_for_bash_i+=2)); do
    __chatgpt_for_bash_json_chat_hist+=("{\"role\": \"user\", \"content\": $(echo -E ${__chatgpt_for_bash_chat_hist[@]:$__chatgpt_for_bash_i:1} | jq -R '.')}, \
{\"role\": \"assistant\", \"content\": $(echo -E ${__chatgpt_for_bash_chat_hist[@]:$__chatgpt_for_bash_i+1:1} | jq -R '.')},")
  done
  __chatgpt_for_bash_json_chat_hist_str=$(echo -E -n "${__chatgpt_for_bash_json_chat_hist[@]}" | tr '\n' '\\n')

  __chatgpt_for_bash_escaped_question=$(echo -E "$__chatgpt_for_bash_question" | jq -R '.' | cut -c 2- | rev | cut -c 2- | rev)
  __chatgpt_for_bash_request="{
    \"model\": \"gpt-4o-mini\",
    \"response_format\": { \"type\": \"json_object\" },
    \"messages\": [
      {\"role\": \"system\", \"content\": \"You are a helpful assistant designed to output JSON. Your task is to provide helpful bash commands that do what a user asks of you. Always return a JSON object with 'command' and 'explanation' fields. The explanation should be very brief, 1 sentence.\"},
      {\"role\": \"user\", \"content\": \"get my git commits from the last 7 days\"},
      {\"role\": \"assistant\", \"content\": \"{\\\"command\\\": \\\"git log --author=\\\\\\\"\$(git config user.name)\\\\\\\" --since=\\\\\\\"7 days ago\\\\\\\"\\\", \\\"explanation\\\": \\\"This command retrieves your git commits from the past week.\\\"}\"},
      {\"role\": \"user\", \"content\": \"get current date with daterania\"},
      {\"role\": \"assistant\", \"content\": \"{\\\"command\\\": \\\"\\\", \\\"explanation\\\": \\\"Sorry, I'm not familiar with daterania and cannot provide a command for it.\\\"}\"},
      {\"role\": \"user\", \"content\": \"i made it more robust, add current dir, commit and push\"},
      {\"role\": \"assistant\", \"content\": \"{\\\"command\\\": \\\"git add . && git commit -m 'made things more robust' && git push\\\", \\\"explanation\\\": \\\"This command stages all changes, commits with a message, and pushes to the remote repository.\\\"}\"},
      ${__chatgpt_for_bash_json_chat_hist_str}
      {\"role\": \"user\", \"content\": \"$__chatgpt_for_bash_escaped_question\"}
    ],
    \"temperature\": 0
  }"

  __chatgpt_for_bash_response_raw=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $__chatgpt_for_bash_api_key" \
    -d "$__chatgpt_for_bash_request" \
    https://api.openai.com/v1/chat/completions)

  __chatgpt_for_bash_response=$(echo -E "$__chatgpt_for_bash_response_raw" | jq -r '.choices[0].message.content')
  __chatgpt_for_bash_command=$(echo -E "$__chatgpt_for_bash_response" | jq -r '.command')
  __chatgpt_for_bash_explanation=$(echo -E "$__chatgpt_for_bash_response" | jq -r '.explanation')

  if [[ -z "$__chatgpt_for_bash_command" ]]; then
    echo -E "Empty response, please try a different prompt." >&2
    read -r __chatgpt_for_bash_input
    __chatgpt_for_bash_question="$__chatgpt_for_bash_input"
    generate_command
  else
    printf "I think I can do that with the following command:\n\n  " >&2
    bold_start
    echo -E "$__chatgpt_for_bash_command" >&2
    bold_end
    printf "\n\nExplanation: $__chatgpt_for_bash_explanation\n\n" >&2
    check_command_input
  fi
}

if [[ -n "$ZSH_VERSION" ]]; then
  __chatgpt_for_bash_shell="zsh"
else
  __chatgpt_for_bash_shell="bash"
fi

__chatgpt_for_bash_question="$*"
__chatgpt_for_bash_api_key="$OPENAI_API_KEY"
__chatgpt_for_bash_chat_hist=()

if [ -z "$__chatgpt_for_bash_question" ]; then
  echo -E "Error: Please provide a question" >&2
  if [ "$0" = "${BASH_SOURCE[0]}" ]; then
    exit 1
  else
    return 1
  fi
fi

if [ -z "$__chatgpt_for_bash_api_key" ]; then
  echo -E "Error: Please set the OPENAI_API_KEY environment variable" >&2
  if [ "$0" = "${BASH_SOURCE[0]}" ]; then
    exit 1
  else
    return 1
  fi
fi

generate_command
