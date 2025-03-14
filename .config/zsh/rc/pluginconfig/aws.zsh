# AWS Service Reference URL
SERVICE_REFERENCE_URL="https://servicereference.us-east-1.amazonaws.com"
SERVICES_JSON="$HOME/.aws_services.json"

function get_aws_service_url() {
  # Fetch JSON data (only on first run)
  if [ ! -f "$SERVICES_JSON" ]; then
    echo "📥 Fetching AWS service list..."
    curl -s "${SERVICE_REFERENCE_URL}" > "$SERVICES_JSON"
  fi

  # Check if data is correctly stored using `jq`
  if [ "$(jq length < "$SERVICES_JSON")" -eq 0 ]; then
    echo "⚠️ Failed to fetch service list. Please try again."
    rm -f "$SERVICES_JSON"
    return 1
  fi

  # Select service using `fzf`
  local SERVICE=$(jq -r '.[].service' "$SERVICES_JSON" | fzf --prompt "Select an AWS service: ")

  if [ -z "$SERVICE" ]; then
    echo "❌ No service selected"
    return 1
  fi

  # Get the URL of the selected service
  local SERVICE_URL=$(jq -r --arg SERVICE "$SERVICE" '.[] | select(.service == $SERVICE) | .url' "$SERVICES_JSON")

  # Display the URL
  echo "🔗 URL of the selected service: $SERVICE_URL"

  # Copy to clipboard (supports macOS and Linux)
  if command -v pbcopy &> /dev/null; then
    echo -n "$SERVICE_URL" | pbcopy
    echo "📋 URL copied to clipboard (macOS)"
  elif command -v xclip &> /dev/null; then
    echo -n "$SERVICE_URL" | xclip -selection clipboard
    echo "📋 URL copied to clipboard (Linux)"
  else
    echo "⚠️ Clipboard copy is not supported"
  fi
}

