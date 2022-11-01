#!/usr/bin/env bash
set -Ceu
#---------------------------------------------------------------------------
# SQLite3のFTS5で全文検索できるか試す。
# CreatedAt: 2022-11-01
#---------------------------------------------------------------------------
Run() {
	THIS="$(realpath "${BASH_SOURCE:-0}")"; HERE="$(dirname "$THIS")"; PARENT="$(dirname "$HERE")"; THIS_NAME="$(basename "$THIS")"; APP_ROOT="$PARENT";
	cd "$HERE"
	DB=highlight.db
	Sql() { sqlite3 -batch -tabs "$DB" "$1"; }
	[ -f "$DB" ] || {
		Sql "create virtual table fts_articles using fts5(id, title, content);"
		Sql "insert into fts_articles values(0, 'This is a title', 'This is a content.'), (1, 'Some title', 'Some content.'), (2, 'Is is a title', 'Is is a content.');"
	}
	Sql "select id, title, highlight(fts_articles, 2, '<b>', '</b>') from fts_articles where content match 'is' order by rank;"
}
Run "$@"
