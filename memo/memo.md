SQLite3のFTS5で全文検索してみる

　超かんたんに試してみた。

<!-- more -->

# ブツ

* [][]

[]:https://github.com/ytyaru/

# 実行

```sh
NAME=''
git clone https://github.com/ytyaru/$NAME
cd $NAME/src
./min.sh
./rank.sh
./highlight.sh
./snippet.sh
./and.sh
```

# [FTS5][]

[FTS5]:https://www.sqlite.org/fts5.html

　[FTS5][]は`Full Text Search`の略。`5`はバージョン値。SQLite3における全文検索する機能のこと。

　全文検索するためには専用の仮想テーブルを作る必要がある。また、そのテーブルの列はすべてテキスト型らしい。そのうえ標準では英語のようにASCIIかつ半角スペース区切りでないと検索できないっぽい。

　そのへんの実装はトークナイザと呼ばれるもので、C言語で書いているようだ。日本語で全文検索するなら日本語用のトークナイザが必要。その実装は超絶大変だろうから、ひとまず英語でFTS5の機能をたしかめてみる。

# 最速でFTS5を体験する

## `match`で検索キーワードを指定する

```sh
sqlite3 min.db
```
```sql
create virtual table fts_articles using fts5(id, title, content);
```
```sql
insert into fts_articles values(0, 'This is a title', 'This is a content.'), (1, 'Some title', 'Some content.');
```
```sql
select * from fts_articles where content match 'is';
```
```sh
0|This is a title|This is a content.
```

　`is`という単語が`content`列に含まれたレコードを抽出した。

　テーブル作成についてはふつうにIDで検索するとき用の通常テーブルと、全文検索用の仮想テーブルで２つ別々に作る必要があるのかもしれない。だとしたらすごく面倒くさい。

　FTS5用仮想テーブル作成SQL文には独自の構文が使われている。`virtual`やら`using fts5`がそれ。

　`insert`はふつうにできた。

　`select`は`match`句を使う。これはFTS5用の句。大文字・小文字を区別しない。

## rankで関連の高い順に表示する

```sh
sqlite3 rank.db
```
```sql
create virtual table fts_articles using fts5(id, title, content);
```
```sql
insert into fts_articles values(0, 'This is a title', 'This is a content.'), (1, 'Some title', 'Some content.'), (2, 'Is is a title', 'Is is a content.');
```
```sql
select * from fts_articles where content match 'is';
```
```sh
0	This is a title	This is a content.
2	Is is a title	Is is a content.
```
```sql
select * from fts_articles where content match 'is' order by rank;
```
```sh
2	Is is a title	Is is a content.
0	This is a title	This is a content.
```

　`order by rank`がポイント。FTS5仮想テーブルには`rank`でソートする機能があり関連性が高い順にソートするらしい。その関連性の高さはトークナイザが判断しているのだろう。

　最初の`select`と次の`select`では順序が逆転している。後者のほうに`order by rank`がある。たぶん検索語の`is`が多い順に並んでいるのだと思う。

## ヒットした語をハイライトする

　[highlight][]関数を使うのがポイント。

[highlight]:https://www.sqlite.org/fts5.html#the_highlight_function

位置|意味
----|----
1|対象となるFTSテーブル名
2|対象となるFTSテーブル列のインデックス（`0`〜）
3|一致した語の前に挿入するテキスト
4|一致した語の後に挿入するテキスト

```sh
sqlite3 highlight.db
```
```sql
create virtual table fts_articles using fts5(id, title, content);
```
```sql
insert into fts_articles values(0, 'This is a title', 'This is a content.'), (1, 'Some title', 'Some content.'), (2, 'Is is a title', 'Is is a content.');
```
```sql
select id, title, highlight(fts_articles, 2, '<b>', '</b>') from fts_articles where content match 'is' order by rank;
```
```sh
2	Is is a title	<b>Is</b> <b>is</b> a content.
0	This is a title	This <b>is</b> a content.
```

## 抜粋する

　[snippet][]関数を使う。ヒットした語のまわりから抜粋する。

位置|意味
----|----
1|対象となるFTSテーブル名
2|対象となるFTSテーブル列のインデックス（`0`〜）
3|一致した語の前に挿入するテキスト
4|一致した語の後に挿入するテキスト
5|一致した語の前後に挿入する（先頭／末尾でない印）
6|最大トークン数（`1`〜`64`）

[snippet]:https://www.sqlite.org/fts5.html#the_snippet_function

```sh
sqlite3 snippet.db
```
```sql
create virtual table fts_articles using fts5(id, title, content);
```
```sql
insert into fts_articles values(0, 'This is a title', 'This is a content. I am Andy.'), (1, 'Some title', 'Some content. I am Sum.'), (2, 'Is is a title', 'Is is a content.');
```
```sql
select id, title, snippet(fts_articles, 2, '<b>', '</b>', '', 3) from fts_articles where content match 'is' order by rank;
```
```sh
2	Is is a title	<b>Is</b> <b>is</b> a
0	This is a title	This <b>is</b> a
```

　最初にヒットした語から指定した`3`語まで表示された。

　これもきっとスペース区切りだろうから日本語ではまともに動作しない予感。

## 論理演算`AND`

　ふつう検索といったら複数の語で`AND`検索して絞り込んでゆくもの。

```sh
sqlite3 and.db
```
```sql
create virtual table fts_articles using fts5(id, title, content);
```
```sql
insert into fts_articles values(0, 'This is a title', 'This is a content. I am Andy.'), (1, 'Some title', 'Some content. I am Sum.'), (2, 'Is is a title', 'Is is a content.'), (3, 'Andy', 'Andy Andy.');
```
```sql
select id, title, snippet(fts_articles, 2, '<b>', '</b>', '', 3) from fts_articles where content match 'is' and  content match 'Andy' order by rank;
```
```sh
0	This is a title	This <b>is</b> a
```

　`is`と`Andy`の2語が`content`列に含まれているレコードは`id`=`0`のひとつだけ。期待どおり。

# 所感

　英語ならこれで大体使えるはず。

　でもね、私は日本語で使いたいんですよ。英語なんて「これはペンです」「私はアンディです」くらいしかわかりません。

　日本語で使うには日本語用のトークナイザをC言語で実装せねばならないそうで。しかもSQLite3が提供するFTS5用APIなどを使いこなす必要があるようで。ハードルが高すぎてハゲそう。でもググったらそれらしきコードがありました。次はそれが本当に使えるのか試してみる予定。

