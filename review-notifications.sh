#!/bin/bash

source ./.env

read -p "Do you want to include read notifications? (y/n): " include_read
if [[ "$include_read" == "y" ]]; then
  all_notifications=true
else
  all_notifications=false
fi

# Fetch notifications from GitHub API (4 pages, to work around default limit of max 50 items)
notifications=""
for page in {1..4}; do
  notifications+=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/notifications?all=${all_notifications}&per_page=50&page=$page")
done

# Fetch organizations the user is a member of
orgs=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user/orgs | jq -r '.[].login')

# Extract repository names from notifications related to pull requests
repos=$(echo "$notifications" | jq -r '.[] | select(.subject.type == "PullRequest" and .reason != "done") | .repository.full_name' | sort | uniq)

# Fetch the username of the authenticated user
username=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" https://api.github.com/user | jq -r '.login')

# Filter repositories based on organizations and user ownership
filtered_repos=""
for repo in $repos; do
  org=$(echo "$repo" | cut -d'/' -f1)
  if echo "$orgs" | grep -q "$org" || [ "$org" == "$username" ]; then
    filtered_repos+="$repo"$'\n'
  fi
done

# Print repository names
echo "Your repositories in your GitHub PR notifications:"
echo "$filtered_repos"

# Print the number of repositories
repo_count=$(echo "$filtered_repos" | wc -l)
echo "Number of identified repositories: $repo_count"

read -p "Do you want to continue with the review process? (y/n): " choice
if [[ "$choice" != "y" ]]; then
  echo "Review process aborted."
  exit 0
fi

for repo in $filtered_repos; do
  echo "Checking repository: $repo"

  # Link to notifications
  # Example:
  # https://github.com/notifications?query=repo%3Awetransform%2Fadv-inspire-alignments

  link="https://github.com/notifications?query=repo%3A$(echo "$repo" | sed 's/\//%2F/g')"
  link_length=${#link}
  box_width=$((link_length + 17))

  top_border=$(printf '┌%*s┐\n' "$box_width" '' | tr ' ' '-')
  middle_border=$(printf '│ Notifications: %s │\n' "$link")
  bottom_border=$(printf '└%*s┘\n' "$box_width" '' | tr ' ' '-')

  echo "$top_border"
  echo "$middle_border"
  echo "$bottom_border"



  # Run review for repo; exit if it fails
  if ! ./review-repo.sh "$repo"; then
    echo "Error: review-repo.sh failed for $repo. Aborting notification processing."
    exit 1
  fi

  # Prompt user to confirm processing notifications for this repo (default: yes, 10s timeout, single keypress)
  echo -n "Do you want to process notifications for $repo? (continues automatically after 10s) [Y/n/d=done]: "
  read -r -n 1 -t 10 process_choice
  if [ $? -gt 128 ]; then
    # read timed out
    process_choice="Y"
    echo
  fi
  process_choice=${process_choice:-Y}
  echo
  if [[ "$process_choice" =~ ^[Nn]$ ]]; then
    echo "Skipping notification processing for $repo."
    continue
  fi
  mark_all_done=false
  if [[ "$process_choice" =~ ^[Dd]$ ]]; then
    mark_all_done=true
    echo "All matching notifications for $repo will be marked as done."
  fi

  # Fetch notifications for the repository
  repo_notifications=$(echo "$notifications" | jq -r --arg repo "$repo" '.[] | select(.repository.full_name == $repo)')

  # Iterate over notifications and mark as done if related to merged pull requests
  for notification in $(echo "$repo_notifications" | jq -r '.id'); do
    pr_url=$(echo "$repo_notifications" | jq -r --arg id "$notification" 'select(.id == $id) | .subject.url')
    pr_data=$(curl -s -H "Authorization: Bearer $GITHUB_TOKEN" "$pr_url")
    pr_state=$(echo "$pr_data" | jq -r '.state')

    # Derive HTML URL for the PR from the API URL
    pr_html_url=$(echo "$pr_url" | sed 's|api\\.|www.|; s|repos/||; s|/pulls/|/pull/|')

    echo "PR state for $pr_html_url: $pr_state"

    proceed_marking=false
    if [ -z "$LABELS" ]; then
      # LABELS not set, always proceed
      proceed_marking=true
    else
      # LABELS is set, check for label match
      pr_labels=$(echo "$pr_data" | jq -r '[.labels[].name] | join(",")')
      IFS=',' read -ra label_arr <<< "$LABELS"
      for label in "${label_arr[@]}"; do
        if [[ ",$pr_labels," == *",$label,"* ]]; then
          proceed_marking=true
          echo "Label match found: $label in $pr_labels"
          break
        fi
      done
      if [ "$proceed_marking" = false ]; then
        echo "No label match for PR $pr_html_url, skipping notification."
      fi
    fi

    if [ "$proceed_marking" = true ]; then
      if [ "$mark_all_done" = true ] || [ "$pr_state" == "closed" ]; then
        curl -s -X DELETE -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/notifications/threads/$notification"
        echo "Marked notification for PR $pr_html_url as done"
      else
        curl -s -X PATCH -H "Authorization: Bearer $GITHUB_TOKEN" "https://api.github.com/notifications/threads/$notification" > /dev/null
        echo "Marked notification for PR $pr_html_url as read"
      fi
    fi
  done
done
