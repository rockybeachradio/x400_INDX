#!/usr/bin/env bash
set -euo pipefail

################################################################################################
# File: git_clone_pull.sh
# Author: Andreas
# Date: 20260827
# Purpose: Downloads the newest data from GitHub Repository
# Called by: install.sh, update.sh
#
################################################################################################
echo "This is $(basename "$0")"

################################################################################################
## Variables
################################################################################################
FORCE_PULL=false    # script calle dwith -force_pull

REPO_URL=""
DEST=""

######################################################
#Resolve repo root (parent of this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
BASE_DIR="$(cd "$REPO_DIR/.." && pwd)"


################################################################################################
# Get parameters & Provide usage infos
################################################################################################
# Help text for users --> How to call this script
usage_info() {
  echo "Usage: $0 [-f] [-d <DEST_PATH>] [-r <REPO_URL>]"
  echo "  -d, --dest:     Local directory for the repo"
  echo "                  If DEST_PATH is not provided: Update this project (parent of scripts/ = REPO_DIR)"
  echo "  -r, --repo:     Git remote URL (https or ssh)"
  echo "                  REPO_URL only required when DEST_PATH is not an existing git repo"
  echo "  -f, --force_pull:    Fetch remote and overwrite local changes (git reset --hard + clean)"
  echo " "

  echo "Examples:"
  echo "./$(basename "$0")"
  echo "./$(basename "$0") -d /path/to/repo"
  echo "./$(basename "$0") -d /path/to/repo -r https://github.com/user/repo.git"
  echo "./$(basename "$0") -f 
  "
}

# Get parameters
echo "Get Parameters"
while [[ $# -gt 0 ]]; do
  case "$1" in
    -f|--force_pull)
      FORCE_PULL=true
      shift ;;
    -r|--repo)
      [[ $# -ge 2 ]] || { echo "❌ $1 needs a value" >&2; usage_info; exit 2; }
      REPO_URL="$2"
      shift 2
      ;;
    -d|--dest)
      [[ $# -ge 2 ]] || { echo "❌ $1 needs a value" >&2; usage_info; exit 2; }
      DEST="$2"
      shift 2
      ;;
    -h|--help)
      usage_info
      exit 2 ;;
    *)
      echo "Unknown option: $1" >&2
      usage_info
      exit 2
      ;;
  esac
done


# No DEST_PATH provided --> Use this scripts Repository directory
if [[ -z "$DEST" ]]; then
  DEST="$REPO_DIR"
fi




# Relative -> absolute (based on the caller’s current directory)
if [[ "$DEST" != /* ]]; then
  DEST="$(pwd)/$DEST"
fi

dest_parent="$(dirname "$DEST")"
dest_name="$(basename "$DEST")"

if [[ -d "$dest_parent" ]]; then
  DEST="$(cd "$dest_parent" && pwd)/$dest_name"
else
  # parent not created yet; keep logical path, clone section will mkdir -p
  DEST="$dest_parent/$dest_name"
fi



# REPO_URL only required when DEST is not an existing git repo
if [[ -z "$REPO_URL" ]]; then
  if [[ -d "$DEST/.git" ]]; then
    REPO_URL=$(git -C "$DEST" remote get-url origin)
    echo "ℹ️  No URL given — using origin: $REPO_URL"
  else
    echo "❌ REPO_URL is required when the destination is not an existing git repo." >&2
    usage_info
    exit 2
  fi
fi

echo "ℹ️  Remote Repository URL: $REPO_URL"
echo "ℹ️  Local folder: $DEST"




################################################################################################
# Ask if force_pull is really wanted.
################################################################################################
if $FORCE_PULL; then
  echo "ℹ️  You selected force_pull. All local changes will be reset to the GitHub version."
  read -p "❓ Are you sure? [y/N]: " answer
  answer=${answer:-N}     # default to "N" if empty
  if [[ "$answer" =~ ^[Yy]$ ]]; then
    FORCE_PULL=true
  else
    FORCE_PULL=false
    echo "Lets continue with normal pull"
  fi
fi







################################################################################################
# Clone if local repo does not exist
################################################################################################
if [[ ! -e "$DEST" ]]; then
  echo "ℹ️  No local repo at $DEST"
  echo "Creating diretory and cloning remote Repository..."
  mkdir -p "$(dirname "$DEST")"
  git clone "$REPO_URL" "$DEST"
  echo "✅ Cloned $REPO_URL -> $DEST"
  exit 0
fi

if [[ ! -d "$DEST" ]]; then
  echo "❌  Destination exists but is not a directory: $DEST" >&2
  exit 3
fi

if [[ ! -d "$DEST/.git" ]]; then
  # Empty directory: clone into it. Non-empty non-git: refuse.
  if [[ -z "$(ls -A "$DEST")" ]]; then
    echo "ℹ️  Empty directory $DEST"
    echo "Cloning into it..."
    git clone "$REPO_URL" "$DEST"
    echo "✅ Cloned $REPO_URL -> $DEST"
    exit 0
  fi
  echo "❌  $DEST exists but is not a git repository and is not empty !" >&2
  exit 3
fi




################################################################################################
# Go to Repository directory
################################################################################################
# Go to $DEST directory
cd "$DEST" || { echo "❌  Cannot enter local Repository directory: $DEST"; exit 1; }


##################################################
# Warn if origin URL differs from the requested URL
if ORIGIN_URL=$(git remote get-url origin 2>/dev/null); then
  if [[ "$ORIGIN_URL" != "$REPO_URL" ]]; then
    echo "⚠️  Origin is '$ORIGIN_URL', requested '$REPO_URL'"
    echo "ℹ️  Continuing with the existing origin."
  fi
fi






################################################################################################
# Upstream check
################################################################################################
# Ensure an upstream is configured (e.g., origin/master)
if ! git rev-parse --abbrev-ref --symbolic-full-name @{u} >/dev/null 2>&1; then
  CURR_BRANCH=$(git symbolic-ref --short HEAD)        # Try to set upstream to origin/<current-branch>
  if git show-ref --verify --quiet "refs/remotes/origin/$CURR_BRANCH"; then
    git branch --set-upstream-to "origin/$CURR_BRANCH" >/dev/null
  else
    echo "❌ No upstream set and origin/$CURR_BRANCH doesn't exist. Aborting."
    exit 3
  fi
fi


################################################################################################
# Don’t pull over a dirty working tree
################################################################################################
if ! $FORCE_PULL; then
  if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "❌ Working tree has local changes:"
    git status --porcelain
    echo "ℹ️  Commit/stash them, or run: $0 -f -r \"$REPO_URL\" -d \"$DEST\""
    echo "force_pull will reset all local changes to the GitHub version."
    read -p "❓ Do you want to run: force_pull? [y/N]: " answer
    answer=${answer:-N}     # default to "N" if empty
    if [[ "$answer" =~ ^[Yy]$ ]]; then
        FORCE_PULL=true
        echo "ℹ️  okay, lets forde_pull the new version form GitHub."
    else
        echo "ℹ️  Script wil exit now."
        exit 4
    fi
  fi
fi


################################################################################################
# Force pull from GitHub
################################################################################################
if $FORCE_PULL; then  # FORCE PULL: overwrite local changes with remote tracking branch
  echo "ℹ️  Force_pull latest from upstream and overwriting local changes..."
  git fetch --prune --quiet   # Download new files. Fetches new commits/refs from the remote GitHub and prunes deleted branches.
  git reset --hard @{u}       # Moves your current branch and your working directory to the upstream branch (@{u} = the configured upstream, e.g. origin/master).
  git clean -fd               # Deletes untracked files and directories (but leaves ignored ones).
  echo "✅ Repository was build up from scratch. Now in synce with GitHub Repo."
  exit 0
fi


################################################################################################
# Check for new Version on GitHub. If newer version: Download it
################################################################################################
# Get data
echo "Get data"
git fetch origin --quiet          # Fetch remote metadata

LOCAL=$(git rev-parse @)          # current local commit
REMOTE=$(git rev-parse @{u})      # Upstream-Commit (origin/master)
BASE=$(git merge-base @ @{u})     # gemeinsamer Vorfahre


if [[ "$LOCAL" == "$REMOTE" ]]; then
  echo "✅  Local Software Repo is up to date."
  exit 5                                      # 5 = no new version available
elif [[ "$LOCAL" == "$BASE" ]]; then
  echo "ℹ️  New version available. Downloading ..."
  git pull --ff-only                        # Fast-forward only (safer, no merge commit)
  exit 0                                    # 0 = everything is okay. update was performed.
elif [[ "$REMOTE" == "$BASE" ]]; then
  echo "ℹ️  Your local version is ahead of the remote version. To go back to last stable version delet the current local Repo and follow the installation instruction."
  exit 6
else
  echo "❌ Local and remote have diverged. Resolve manually or run:"
  echo "   $0 -f -r \"$REPO_URL\" -d \"$DEST\""
  exit 7
fi
exit 8
