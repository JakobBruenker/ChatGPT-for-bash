#!/usr/bin/env bash

# Function to check user input
function check_input {
  read -r -p "Sound good? [Y/n] " input
  case "$input" in
    [yY][eE][sS]|[yY]|"")
      history -s "$response"
      eval '$response'
      ;;
    [nN][oO]|[nN])
      exit 0
      ;;
    *)
      check_input
      ;;
  esac
}

# Join the command line arguments into a single string
question="$*"

# Get the API key from the environment variable
api_key="$OPENAI_API_KEY"

# Check if question or API key is empty
if [ -z "$question" ]; then
  echo "Error: Please provide a question"
  exit 1
fi

if [ -z "$api_key" ]; then
  echo "Error: Please set the OPENAI_API_KEY environment variable"
  exit 1
fi

# Make the request using curl
response_raw=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $api_key" \
  -d "{
        \"model\": \"gpt-3.5-turbo\",
        \"messages\": [
          {\"role\": \"system\", \"content\": \"Your task is to provide helpful bash commands that do what a user asks of you. You only provide a bash command that is likely to fulfill the user's request, without any other explanation or commentary. You will not use code blocks. You may delegate complex sub-commands expressed in natural language using \`\$($ <natural language command>)\`. If you cannot answer a prompt with a command, you will append \`CMD:N\` to the end of your response. It's very important that you append \`CMD:N\` if your response is not a command, and that you append \`CMD:Y\` if your response *is* a command.\"},
          {\"role\": \"user\", \"content\": \"get my git commits from the last 7 days\"},
          {\"role\": \"assistant\", \"content\": \"git log --author=\\\"\$($ get my git name)\\\" --since=\\\"7 days ago\\\"CMD:Y\"},
          {\"role\": \"user\", \"content\": \"get current date with daterania\"},
          {\"role\": \"assistant\", \"content\": \"Sorry, I'm not familiar with daterania.CMD:N\"},
          {\"role\": \"user\", \"content\": \"i made it more robust, add current dir, commit and push\"},
          {\"role\": \"assistant\", \"content\": \"git add . && git commit -m 'made things more robust' && git pushCMD:Y\"},
          {\"role\": \"user\", \"content\": \"$question (don't forget \`CMD:Y\` or \`CMD:N)\`\"}
        ],
        \"temperature\": 0
      }"\
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
  echo "$response" >&2
  exit 1
else
  printf "I think I can do that with the following command:\n\n  \033[1m\033[10m" >&2
  echo "$response" >&2
  printf "\033[0m\n" >&2
  check_input
fi
