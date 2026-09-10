set -euo pipefail

vault=${OBSIDIAN_VAULT_ROOT:-/var/lib/obsidian-vault}
today=$(TZ=Asia/Tehran date +%F)
archive_root="$vault/Archive"
scan_only=false

if [ "${1:-}" = "--scan-only" ]; then
  scan_only=true
elif [ "$#" -ne 0 ]; then
  echo "Usage: archive-obsidian-notes [--scan-only]" >&2
  exit 2
fi

# Weeks run Saturday through Friday. On Saturday, archive exactly the week
# which ended the previous day.
weekday=$(TZ=Asia/Tehran date -d "$today" +%u)
days_since_saturday=$(( (weekday + 1) % 7 ))
current_week_start=$(TZ=Asia/Tehran date -d "$today - $days_since_saturday days" +%F)
last_week_start=$(TZ=Asia/Tehran date -d "$current_week_start - 7 days" +%F)
last_week_end=$(TZ=Asia/Tehran date -d "$current_week_start - 1 day" +%F)

archived_daily=0
archived_briefings=0

archive_last_week() {
  source_name=$1
  source_dir="$vault/$source_name"

  [ -d "$source_dir" ] || return 0

  while IFS= read -r -d '' note; do
    file_name=${note##*/}
    note_date=${file_name%.md}
    note_month=${note_date%??}
    note_month=${note_month%-}

    case "$note_date" in
      ????-??-??) ;;
      *) continue ;;
    esac

    [[ "$note_date" < "$last_week_start" ]] && continue
    [[ "$note_date" > "$last_week_end" ]] && continue

    target_dir="$archive_root/$note_month/$source_name"
    mkdir -p "$target_dir"
    if [ -e "$target_dir/$file_name" ]; then
      if cmp -s -- "$note" "$target_dir/$file_name"; then
        # A prior partial run or a sync replay can leave an identical copy at
        # both paths. Keep the archived copy and remove only the duplicate.
        rm -- "$note"
      else
        # Treat the active note as the latest version, but retain the previous
        # archived version under a content-addressed conflict path. Keeping the
        # original filename beneath a Daily/Briefings directory makes the
        # preserved note easy to identify during manual reconciliation.
        archived_hash=$(sha256sum -- "$target_dir/$file_name")
        archived_hash=${archived_hash%% *}
        conflict_dir="$archive_root/$note_month/Conflicts/$archived_hash/$source_name"
        conflict_note="$conflict_dir/$file_name"
        mkdir -p "$conflict_dir"

        if [ -e "$conflict_note" ]; then
          if ! cmp -s -- "$target_dir/$file_name" "$conflict_note"; then
            echo "Archive conflict hash collision: $conflict_note" >&2
            return 1
          fi
          rm -- "$target_dir/$file_name"
        else
          mv -- "$target_dir/$file_name" "$conflict_note"
        fi

        mv -- "$note" "$target_dir/$file_name"
        echo "Preserved different archive note at: $conflict_note" >&2
      fi
    else
      mv -- "$note" "$target_dir/$file_name"
    fi

    if [ "$source_name" = Daily ]; then
      archived_daily=$((archived_daily + 1))
    else
      archived_briefings=$((archived_briefings + 1))
    fi
  done < <(find "$source_dir" -maxdepth 1 -type f -name '????-??-??.md' -print0)
}

if ! $scan_only; then
  archive_last_week Daily
  archive_last_week Briefings
fi

# Scan both active and archived Daily folders so unfinished tasks stay visible.
todos_json=$(
  find "$vault/Daily" "$archive_root" -type f \
    \( -path "$vault/Daily/????-??-??.md" -o -path "$archive_root/????-??/Daily/????-??-??.md" \) \
    -print0 2>/dev/null |
    sort -z |
    while IFS= read -r -d '' note; do
      file_name=${note##*/}
      note_date=${file_name%.md}
      [[ "$note_date" < "$today" ]] || continue

      awk -v date="$note_date" -v path="${note#"$vault/"}" '
        match($0, /^[[:space:]]*[-*][[:space:]]+\[[[:space:]]\][[:space:]]+(.+)/, task) {
          if (task[1] != "") {
            printf "\036%s\037%s\037%s\n", date, path, task[1]
          }
        }
      ' "$note"
    done |
    jq -Rs '
      split("\n")
      | map(select(length > 0) | ltrimstr("\u001e") | split("\u001f"))
      | map({date: .[0], path: .[1], text: .[2]})
    '
)

jq -cn \
  --argjson remainingTodos "$todos_json" \
  --argjson archivedDaily "$archived_daily" \
  --argjson archivedBriefings "$archived_briefings" \
  '{remainingTodos: $remainingTodos, archivedDaily: $archivedDaily, archivedBriefings: $archivedBriefings}'
