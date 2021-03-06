# qnyp GraphQL API Example (Ruby)

このリポジトリには、Rubyから[qnyp GraphQL API](http://developer.qnyp.com)を呼び出す以下のサンプルスクリプトが含まれています。

- `search_titles.rb` - タイトルをキーワード検索して結果を出力します
- `get_title.rb` - タイトルの情報を取得して結果を出力します
- `create_log.rb` - エピソードの視聴ログを記録します

サンプルを実行するにはqnypのアクセストークンが必要です。

## アクセストークンの取得

qnypにログインした状態で [https://qnyp.com/settings/api](https://qnyp.com/settings/api) にアクセスすると、 `write` スコープを持つ自分用のアクセストークンを生成することができます。

<img src="./images/personal-access-token.jpg" width="550" height="480" alt="Screenshot" />

## 準備

```console
$ ruby -v
ruby 2.4.1p111 (2017-03-22 revision 58053) [x86_64-darwin16]

$ git clone https://github.com/qnyp/qnyp-graphql-example-ruby.git
$ cd qnyp-graphql-example-ruby
$ bundle install --path .bundle
```

## search_titles.rb

環境変数`ACCESS_TOKEN`にアクセストークンの値を、引数に検索キーワードを指定します。

```console
$ ACCESS_TOKEN=アクセストークン bundle exec ./search_titles.rb 検索キーワード
```

実行例:

<img src="./images/example1.png" width="803" height="235" alt="Screenshot" />

## get_title.rb

環境変数`ACCESS_TOKEN`にアクセストークンの値を、引数にタイトルのIDを指定します。

```console
$ ACCESS_TOKEN=アクセストークン bundle exec ./get_title.rb タイトルのID
```

実行例:

<img src="./images/example2.png" width="640" height="540" alt="Screenshot" />

## create_log.rb

環境変数`ACCESS_TOKEN`にアクセストークンの値を、引数に対象のエピソードおよび記録する内容を指定します。
本文を指定しなかった場合は、本文の無い視聴ログが作成されます。

```console
$ ACCESS_TOKEN=アクセストークン bundle exec ./create_log.rb エピソードのID 評価 本文
```

実行例:

```console
$ ACCESS_TOKEN=アクセストークン bundle exec ./create_log.rb RXBpc29kZS03NDkyOA GREAT "すごーい！"

id: TG9nLTIxMTcw
databaeId: XXXXX
createdAt: 2017-04-28T11:11:00Z
body: すごーい！
rating: GREAT
user.username: junya
episode.subtitle: さばんなちほー
url: http://qnyp.com/junya/logs/XXXXX
```
