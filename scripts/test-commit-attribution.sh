#!/bin/sh
set -eu

root=$(cd "$(dirname "$0")/.." && pwd)
rule="$root/.githooks/commit-attribution.sh"
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
passed=0
failed=0

expect() {
  want=$1 name=$2 body=$3
  printf '%b' "$body" > "$work/msg"
  if sh "$rule" msg "$work/msg" "$name" 2>"$work/err"; then got=pass; else got=fail; fi
  if [ "$got" = "$want" ]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL $name: wanted $want, got $got"; cat "$work/err"; fi
}

expect pass "spark trailer" 'Fix thing\n\nCo-authored-by: Spark <spark@final-phase.com>\nAgent-Model: gpt-test\n'
expect pass "claude code trailer" 'Fix thing\n\nCo-authored-by: Claude Code <noreply@anthropic.com>\nAgent-Model: Opus 5.5\n'
expect pass "codex trailer" 'Fix\n\nCo-authored-by: Codex <noreply@openai.com>\nAgent-Model: codex-1\n'
expect pass "grok build trailer" 'Fix\n\nCo-authored-by: Grok Build <noreply@x.ai>\nAgent-Model: grok-build\n'
expect pass "human gabe" 'Hand edit\n\nHuman: Gabe\n'
expect pass "crlf body" 'Fix\r\n\r\nCo-authored-by: Codex <noreply@openai.com>\r\nAgent-Model: codex-1\r\n'
expect pass "comment lines ignored" 'Fix\n\nCo-authored-by: Codex <noreply@openai.com>\nAgent-Model: codex-1\n# Please enter the commit message\n'
expect pass "other human co-author kept" 'Fix\n\nCo-authored-by: Sam Lee <sam@example.com>\nCo-authored-by: Codex <noreply@openai.com>\nAgent-Model: codex-1\n'
expect fail "no trailer" 'Fix thing\n'
expect fail "gabe co-author only" 'Fix\n\nCo-authored-by: Gabe Russo <gabriel.russo@final-phase.com>\n'
expect fail "gabe co-author beside agent" 'Fix\n\nCo-authored-by: Spark <spark@final-phase.com>\nCo-authored-by: Gabe Russo <gabriel.russo@final-phase.com>\nAgent-Model: m\n'
expect fail "missing model" 'Fix\n\nCo-authored-by: Spark <spark@final-phase.com>\n'
expect fail "empty model" 'Fix\n\nCo-authored-by: Spark <spark@final-phase.com>\nAgent-Model: \n'
expect fail "two agents" 'Fix\n\nCo-authored-by: Spark <spark@final-phase.com>\nCo-authored-by: Codex <noreply@openai.com>\nAgent-Model: m\n'
expect fail "wrong case key" 'Fix\n\nCo-Authored-By: Spark <spark@final-phase.com>\nAgent-Model: m\n'
expect fail "model in name" 'Fix\n\nCo-authored-by: Claude Opus 5.5 <noreply@anthropic.com>\nAgent-Model: Opus 5.5\n'
expect fail "old spark name" 'Fix\n\nCo-authored-by: Spark (Final Phase CTO) <spark@final-phase.com>\nAgent-Model: m\n'
expect fail "trailer not in last paragraph" 'Fix\n\nCo-authored-by: Spark <spark@final-phase.com>\nAgent-Model: m\n\nMore text after.\n'
expect fail "human plus agent" 'Fix\n\nHuman: Gabe\nCo-authored-by: Spark <spark@final-phase.com>\nAgent-Model: m\n'

repo="$work/repo"
git init -q "$repo"
git -C "$repo" config user.name Tester
git -C "$repo" config user.email tester@example.com
git -C "$repo" config core.hooksPath "$root/.githooks"
commit() {
  git -C "$repo" -c user.name="$1" commit -q --allow-empty -m "$2" 2>"$work/err"
}
hook_case() {
  want=$1 name=$2 author=$3 message=$4
  if commit "$author" "$message"; then got=pass; else got=fail; fi
  if [ "$got" = "$want" ]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL hook $name: wanted $want, got $got"; cat "$work/err"; fi
}
hook_case pass "base commit" Tester "$(printf 'Base\n\nHuman: Gabe')"
base=$(git -C "$repo" rev-parse HEAD)
hook_case fail "hook rejects bare message" Tester "Bare message"
hook_case pass "hook accepts agent trailer" Tester "$(printf 'Good\n\nCo-authored-by: Spark <spark@final-phase.com>\nAgent-Model: m')"

good=$(printf 'Good\n\nCo-authored-by: Codex <noreply@openai.com>\nAgent-Model: m')
git -C "$repo" -c core.hooksPath=/dev/null -c user.name='dependabot[bot]' commit -q --allow-empty -m "Bump x"
git -C "$repo" checkout -q -b side "$base"
commit Tester "$good"
git -C "$repo" checkout -q -
if git -C "$repo" merge -q --no-ff --no-edit side 2>"$work/err"; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL hook skips merge commits"; cat "$work/err"; fi

range_case() {
  want=$1 name=$2
  if (cd "$repo" && sh "$rule" range "$base" HEAD) 2>"$work/err"; then got=pass; else got=fail; fi
  if [ "$got" = "$want" ]; then passed=$((passed + 1)); else failed=$((failed + 1)); echo "FAIL range $name: wanted $want, got $got"; cat "$work/err"; fi
}
range_case pass "agent, dependabot and merge commits"
git -C "$repo" -c core.hooksPath=/dev/null commit -q --allow-empty -m "Forgot the trailer"
range_case fail "one bare commit in range"

echo "commit-attribution tests: $passed passed, $failed failed"
[ "$failed" -eq 0 ]
