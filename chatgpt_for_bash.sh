#!/usr/bin/env bash

function move_cursor_up {
  if command -v tput >/dev/null 2>&1; then
    # if tput is available, use it to move the cursor to get rid of a blank line
    tput cuu1 >&2
  fi
}

function bold_start {
  printf "\033[1m\033[10m" >&2
}

function bold_end {
  printf "\033[0m" >&2
}

# Function to check user input when there was a command response
function check_command_input {
  echo "Sound good? (Enter to accept, Ctrl-C to cancel, or just write more to refine your request)" >&2
  read __chatgpt_for_bash_input
  if [[ -z "$__chatgpt_for_bash_input" ]]; then
    move_cursor_up
    if [[ -z "$ZSH_VERSION" ]]; then
      # if bash
      history -s "$__chatgpt_for_bash_response"
    else
      # if zsh
      print -s "$__chatgpt_for_bash_response"
    fi
    eval "$__chatgpt_for_bash_response"
  else
    __chatgpt_for_bash_chat_hist+=("$__chatgpt_for_bash_question" "$__chatgpt_for_bash_classified_response")
    __chatgpt_for_bash_question="$__chatgpt_for_bash_input"
    generate_command
  fi
}

# Function to check user input when there was no command response
function check_no_command_input {
  echo "Press enter or Ctrl-C to cancel, or just write more to refine your request." >&2
  read __chatgpt_for_bash_input
  if [[ -z "$__chatgpt_for_bash_input" ]]; then
    move_cursor_up
  else
    __chatgpt_for_bash_chat_hist+=("$__chatgpt_for_bash_question" "$__chatgpt_for_bash_classified_response")
    __chatgpt_for_bash_question="$__chatgpt_for_bash_input"
    generate_command
  fi
}

# Function to query the API
function generate_command {
  __chatgpt_for_bash_json_chat_hist=()
  for ((__chatgpt_for_bash_i=0; __chatgpt_for_bash_i<${#__chatgpt_for_bash_chat_hist[@]}; __chatgpt_for_bash_i+=2)); do
    __chatgpt_for_bash_json_chat_hist+=("{\"role\": \"user\", \"content\": \"${__chatgpt_for_bash_chat_hist[$__chatgpt_for_bash_i]//\"/\\\"}\"}, \
{\"role\": \"assistant\", \"content\": \"${__chatgpt_for_bash_chat_hist[$__chatgpt_for_bash_i+1]//\"/\\\"}\"},")
  done
  # replace newlines with \n
  __chatgpt_for_bash_json_chat_hist_str=$(echo -n ${__chatgpt_for_bash_json_chat_hist[@]} | tr '\n' '\\n')

  __chatgpt_for_bash_request="{
    \"model\": \"gpt-3.5-turbo\",
    \"messages\": [
      {\"role\": \"system\", \"content\": \"Your task is to provide helpful bash commands that do what a user asks of you. \
You only provide a $__chatgpt_for_bash_shell command that is likely to fulfill the user's request, without any other explanation or commentary. \
You will not use code blocks. \
If you cannot answer a prompt with a command, you will append \`CMD:N\` to the end of your response. \
It's very important that you append \`CMD:N\` if your response is not a command, and that you append \`CMD:Y\` if your response *is* a command.\"},
      {\"role\": \"user\", \"content\": \"get my git commits from the last 7 days\"},
      {\"role\": \"assistant\", \"content\": \"git log --author=\\\"$(git config user.name)\\\" --since=\\\"7 days ago\\\"CMD:Y\"},
      {\"role\": \"user\", \"content\": \"get current date with daterania\"},
      {\"role\": \"assistant\", \"content\": \"Sorry, I'm not familiar with daterania.CMD:N\"},
      {\"role\": \"user\", \"content\": \"i made it more robust, add current dir, commit and push\"},
      {\"role\": \"assistant\", \"content\": \"git add . && git commit -m 'made things more robust' && git pushCMD:Y\"},
      ${__chatgpt_for_bash_json_chat_hist_str}
      {\"role\": \"user\", \"content\": \"$__chatgpt_for_bash_question (don't forget \`CMD:Y\` or \`CMD:N)\`\"}
    ],
    \"temperature\": 0
  }"

  # Make the request using curl
  __chatgpt_for_bash_response_raw=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $__chatgpt_for_bash_api_key" \
    -d "$__chatgpt_for_bash_request" \
    https://api.openai.com/v1/chat/completions)

  __chatgpt_for_bash_classified_response=$(echo "$__chatgpt_for_bash_response_raw" | jq -r '.choices[0].message.content')
  if [[ "$__chatgpt_for_bash_classified_response" =~ CMD..$ ]]; then
    __chatgpt_for_bash_class="${__chatgpt_for_bash_classified_response: -5}"
    __chatgpt_for_bash_response="${__chatgpt_for_bash_classified_response%?????}"
  else
    __chatgpt_for_bash_class="null"
    __chatgpt_for_bash_response="$__chatgpt_for_bash_classified_response"
  fi

  # Print the response and ask for user input
  if [[ -z "$__chatgpt_for_bash_response" ]]; then
    echo "Empty response, please try a different prompt." >&2
    check_no_command_input
  else
    if [[ "$__chatgpt_for_bash_class" == "CMD:N" ]]; then
      printf "\n" >&2
      bold_start >&2
      echo "$__chatgpt_for_bash_response" >&2
      bold_end
      printf "\n" >&2
      check_no_command_input
    else
      printf "I think I can do that with the following command:\n\n  " >&2
      bold_start
      echo "$__chatgpt_for_bash_response" >&2
      bold_end
      printf "\n" >&2
      check_command_input
    fi
  fi
}

# Find out what shell we're running in
if [[ -n "$ZSH_VERSION" ]]; then
  __chatgpt_for_bash_shell="zsh"
else
  # just use bash as fallback
  __chatgpt_for_bash_shell="bash"
fi

# Join the command line arguments into a single string
__chatgpt_for_bash_question="$*"

# Get the API key from the environment variable
__chatgpt_for_bash_api_key="$OPENAI_API_KEY"

__chatgpt_for_bash_chat_hist=()

# Check if question or API key is empty
if [ -z "$__chatgpt_for_bash_question" ]; then
  echo "Error: Please provide a question" >&2
  if [ "$0" = "$BASH_SOURCE" ]; then
    # script is being called directly
    exit 1
  else
    # script is being sourced
    return 1
  fi
fi

if [ -z "$__chatgpt_for_bash_api_key" ]; then
  echo "Error: Please set the OPENAI_API_KEY environment variable" >&2
  if [ "$0" = "$BASH_SOURCE" ]; then
    # script is being called directly
    exit 1
  else
    # script is being sourced
    return 1
  fi
fi

generate_command
