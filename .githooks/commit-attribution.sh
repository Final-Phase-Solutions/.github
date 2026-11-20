#!/bin/sh
set -eu

ALLOWED='Co-authored-by: Spark <spark@final-phase.com>
Co-authored-by: Claude Code <noreply@anthropic.com>
Co-authored-by: Codex <noreply@openai.com>
Co-authored-by: Grok Build <noreply@x.ai>'
RESERVED='gabe russo|gabriel\.russo@|spark@final-phase\.com|noreply@anthropic\.com|noreply@openai\.com|noreply@x\.ai|cursoragent@cursor\.com'

trailers() {
  tr -d '\r' < "$1" | sed -e '/^# -* >8 -*$/,$d' -e '/^#/d' | git interpret-trailers --parse
}

count() {
  printf '%s\n' "$1" | grep -c "$2" "$3" || true
}

check_message() {
  t=$(trailers "$1")
  agents=$(count "$t" -xF "$ALLOWED")
  models=$(count "$t" -E '^Agent-Model: *[^ ]')
  human=$(count "$t" -x 'Human: Gabe')
  bad=$(printf '%s\n' "$t" | grep -i '^co-authored-by:' | grep -vxF "$ALLOWED" | grep -iE "$RESERVED" || true)
  errors=""
  [ -n "$bad" ] && errors="$errors
  not an allowed agent trailer, replace it with a line below: $bad"
  if [ "$human" -gt 0 ]; then
    [ "$agents" -gt 0 ] && errors="$errors
  has both Human: Gabe and an agent trailer; keep one"
  else
    [ "$agents" -ne 1 ] && errors="$errors
  needs exactly one agent trailer, found $agents"
    [ "$models" -ne 1 ] && errors="$errors
  needs exactly one Agent-Model: <model> trailer, found $models"
  fi
  [ -z "$errors" ] && return 0
  printf '%s fails commit attribution:%s\n' "$2" "$errors" >&2
  printf 'End the message with one of these lines plus Agent-Model: <model>, or with Human: Gabe for a commit Gabe wrote by hand:\n%s\n' "$ALLOWED" | sed 's/^Co/  Co/' >&2
  return 1
}

check_range() {
  msg=$(mktemp)
  status=0
  for sha in $(git rev-list --no-merges "$2" "^$1"); do
    [ "$(git log -1 --format=%an "$sha")" = "dependabot[bot]" ] && continue
    git log -1 --format=%B "$sha" > "$msg"
    check_message "$msg" "commit $(git rev-parse --short "$sha")" || status=1
  done
  rm -f "$msg"
  return $status
}

case "${1:-}" in
  hook)
    [ -e "$(git rev-parse --git-path MERGE_HEAD)" ] && exit 0
    check_message "$2" "commit message" ;;
  msg) check_message "$2" "${3:-message}" ;;
  range) check_range "$2" "$3" ;;
  *) echo "usage: commit-attribution.sh hook <msg-file> | msg <file> [label] | range <base> <head>" >&2; exit 2 ;;
esac
