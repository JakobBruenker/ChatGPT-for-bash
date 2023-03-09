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
  read -r -p "Sound good? (Enter to accept, Ctrl-C to cancel, or just write more to refine your request)
" input
  if [[ -z "$input" ]]; then
    move_cursor_up
    history -s "$response"
    eval "$response"
  else
    chat_hist+=("$question" "$classified_response")
    question="$input"
    generate_command
  fi
}

# Function to check user input when there was no command response
function check_no_command_input {
  read -r -p "Press enter or Ctrl-C to cancel, or just write more to refine your request.
" input
  if [[ -z "$input" ]]; then
    move_cursor_up
    return 1
  else
    chat_hist+=("$question" "$classified_response")
    question="$input"
    generate_command
  fi
}

# Function to query the API
function generate_command {
  json_chat_hist=()
  for ((i=0; i<${#chat_hist[@]}; i+=2)); do
    json_chat_hist+=("{\"role\": \"user\", \"content\": \"${chat_hist[$i]//\"/\\\"}\"}, {\"role\": \"assistant\", \"content\": \"${chat_hist[$i+1]//\"/\\\"}\"},")
  done
  # replace newlines with \n
  json_chat_hist_str=$(echo -n ${json_chat_hist[@]} | tr '\n' '\\n')

  request="{
    \"model\": \"gpt-3.5-turbo\",
    \"messages\": [
      {\"role\": \"system\", \"content\": \"Your task is to provide helpful bash commands that do what a user asks of you. \
You only provide a bash command that is likely to fulfill the user's request, without any other explanation or commentary. \
You will not use code blocks. You may delegate complex sub-commands expressed in natural language using \`\$($ <natural language command>)\`. \
If you cannot answer a prompt with a command, you will append \`CMD:N\` to the end of your response. \
It's very important that you append \`CMD:N\` if your response is not a command, and that you append \`CMD:Y\` if your response *is* a command.\"},
      {\"role\": \"user\", \"content\": \"get my git commits from the last 7 days\"},
      {\"role\": \"assistant\", \"content\": \"git log --author=\\\"\$(? get my git name)\\\" --since=\\\"7 days ago\\\"CMD:Y\"},
      {\"role\": \"user\", \"content\": \"get current date with daterania\"},
      {\"role\": \"assistant\", \"content\": \"Sorry, I'm not familiar with daterania.CMD:N\"},
      {\"role\": \"user\", \"content\": \"i made it more robust, add current dir, commit and push\"},
      {\"role\": \"assistant\", \"content\": \"git add . && git commit -m 'made things more robust' && git pushCMD:Y\"},
      ${json_chat_hist_str}
      {\"role\": \"user\", \"content\": \"$question (don't forget \`CMD:Y\` or \`CMD:N)\`\"}
    ],
    \"temperature\": 0
  }"

  # Make the request using curl
  response_raw=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $api_key" \
    -d "$request" \
    https://api.openai.com/v1/chat/completions)

  classified_response=$(echo "$response_raw" | jq -r '.choices[0].message.content')
  if [[ "$classified_response" =~ CMD..$ ]]; then
    class="${classified_response: -5}"
    response="${classified_response::-5}"
  else
    class="null"
    response="$classified_response"
  fi

  # Print the response and ask for user input
  if [[ "$class" == "CMD:N" ]]; then
    printf "\n" >&2
    bold_start >&2
    echo "$response" >&2
    bold_end
    printf "\n" >&2
    check_no_command_input
  else
    printf "I think I can do that with the following command:\n\n  " >&2
    bold_start
    echo "$response" >&2
    bold_end
    printf "\n" >&2
    check_command_input
  fi
}

# Join the command line arguments into a single string
question="$*"

# Get the API key from the environment variable
api_key="$OPENAI_API_KEY"

chat_hist=()

# Check if question or API key is empty
if [ -z "$question" ]; then
  echo "Error: Please provide a question" >&2
  return 1
fi

if [ -z "$api_key" ]; then
  echo "Error: Please set the OPENAI_API_KEY environment variable" >&2
  return 1
fi

generate_command
