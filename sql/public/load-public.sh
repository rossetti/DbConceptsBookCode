#!/usr/bin/env bash
# =============================================================================
# load-public.sh -- download a public sample database from its original source
# and load it into a PostgreSQL database of its own (@sec-appsampledbs-public).
#
#   code/sql/public/load-public.sh chinook                # into dbconcepts_chinook
#   code/sql/public/load-public.sh northwind my_northwind # into a database you name
#   code/sql/public/load-public.sh employees --replace    # drop and rebuild it
#
# Databases: chinook, northwind, practical, employees. The book ships none of
# them: this script fetches each file from the address in manifest.tsv, pinned
# to one release or commit, and refuses a file whose SHA-256 checksum differs
# from the manifest's, so every reader loads the same data. Files are kept in
# $DBCONCEPTS_CACHE (default ~/.cache/dbconcepts-public) and fetched once.
#
# The target database is created if it does not exist. If it exists, the script
# stops, unless --replace is given, in which case it drops the database first.
# Connection settings come from PGHOST, PGPORT, PGUSER, and PGPASSWORD, as for
# psql. Needs curl, psql, and createdb. Every file reaches psql on its standard
# input, never by a path psql opens itself, so the script also runs in Git Bash
# on Windows, where psql cannot open Git Bash's /c/... paths.
# =============================================================================
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
CACHE="${DBCONCEPTS_CACHE:-$HOME/.cache/dbconcepts-public}"
export PGHOST="${PGHOST:-localhost}"

name="" target="" replace=0
for arg in "$@"; do
  case "$arg" in
    --replace) replace=1 ;;
    -*) echo "unknown option: $arg" >&2; exit 2 ;;
    *) if [ -z "$name" ]; then name="$arg"; else target="$arg"; fi ;;
  esac
done
case "$name" in
  chinook|northwind|practical|employees) ;;
  *) echo "usage: $0 chinook|northwind|practical|employees [database] [--replace]" >&2; exit 2 ;;
esac
target="${target:-dbconcepts_$name}"

BIN=""
command -v psql >/dev/null 2>&1 || BIN="/Applications/Postgres.app/Contents/Versions/latest/bin/"
PSQL="${BIN}psql"
if command -v shasum >/dev/null 2>&1; then SHA="shasum -a 256"; else SHA="sha256sum"; fi

# --- fetch and verify every file of this database ----------------------------
mkdir -p "$CACHE/$name"
while IFS=$'\t' read -r db file url sha bytes license; do
  [ "$db" = "$name" ] || continue
  path="$CACHE/$name/$file"
  if [ ! -f "$path" ]; then
    echo "  fetching $file ($bytes bytes, $license)"
    curl -fsSL -o "$path.part" "$url"
    mv "$path.part" "$path"
  fi
  actual="$($SHA "$path" | cut -d' ' -f1)"
  if [ "$actual" != "$sha" ]; then
    echo "error: $file does not match its checksum in manifest.tsv; delete $path and rerun." >&2
    exit 1
  fi
done < "$HERE/manifest.tsv"

# --- create the target database ------------------------------------------------
exists="$("$PSQL" -XAtqd postgres -c "SELECT 1 FROM pg_database WHERE datname = '$target'")"
if [ "$exists" = "1" ]; then
  if [ "$replace" -eq 1 ]; then
    "$PSQL" -Xq -d postgres -c "DROP DATABASE \"$target\" WITH (FORCE)"
  else
    echo "error: database $target exists; rerun with --replace to drop and rebuild it." >&2
    exit 1
  fi
fi
"$PSQL" -Xq -d postgres -c "CREATE DATABASE \"$target\""

run() { PGOPTIONS="-c client_min_messages=warning" "$PSQL" -Xq -v ON_ERROR_STOP=1 -d "$target" "$@" >/dev/null; }
dir="$CACHE/$name"
case "$name" in
  chinook)
    # The script creates and connects to a database of its own; load its
    # tables into the target instead.
    sed -e '/^DROP DATABASE/d' -e '/^CREATE DATABASE/d' -e '/^\\c /d' \
        "$dir/Chinook_PostgreSql.sql" | run -f - ;;
  northwind)
    run -f - < "$dir/northwind.sql" ;;
  practical)
    run -f - < "$HERE/practical-schema.sql"
    for pair in us_counties_pop_est_2019:us_counties_pop_est_2019 \
                meat_poultry_egg_establishments:MPI_Directory_by_Establishment_Name \
                us_exports:us_exports temperature_readings:temperature_readings; do
      run -c "\\copy ${pair%%:*} FROM pstdin WITH (FORMAT csv, HEADER true)" \
        < "$dir/${pair#*:}.csv"
    done ;;
  employees)
    # The upstream PostgreSQL port creates its tables in a database named
    # employees and loads the MySQL data files with their backquotes removed.
    sed -e '/^DROP DATABASE/d' -e '/^CREATE DATABASE/d' -e '/^\\connect/d' \
        "$dir/employees.sql" | run -f -
    for f in departments employees dept_emp dept_manager titles \
             salaries1 salaries2 salaries3; do
      sed 's/`//g' "$dir/load_$f.dump" | run -f -
    done ;;
esac
"$PSQL" -XAtq -d "$target" -c "SELECT '  $target loaded with $name: '
  || string_agg(table_name, ', ' ORDER BY table_name)
  FROM information_schema.tables
  WHERE table_schema = 'public' AND table_type = 'BASE TABLE'"
