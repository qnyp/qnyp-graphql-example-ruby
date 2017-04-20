#!/usr/bin/env ruby

require 'active_support'
require 'active_support/core_ext'
require 'graphql/client'
require 'graphql/client/http'
require 'terminal-table'

GRAPHQL_ENDPOINT = 'https://api.qnypstaging.com/graphql'.freeze
SCHEMA_DUMP_FILE = './schema.json'.freeze
ACCESS_TOKEN = ENV['ACCESS_TOKEN']

if ACCESS_TOKEN.blank?
  puts '環境変数 ACCESS_TOKEN にアクセストークンを設定してください'
  exit 1
end

# HTTPアダプタの生成
HTTPAdapter = GraphQL::Client::HTTP.new(GRAPHQL_ENDPOINT) do
  def headers(_context)
    # Authorizationヘッダによる認証
    { 'Authorization' => "Bearer #{ACCESS_TOKEN}" }
  end
end

# ローカルにGraphQL Schemaのダンプファイルが存在しない場合はサーバーから取得
unless File.exist?(SCHEMA_DUMP_FILE)
  GraphQL::Client.dump_schema(HTTPAdapter, SCHEMA_DUMP_FILE)
end

# GraphQLクライアントを生成
Client = GraphQL::Client.new(
  execute: HTTPAdapter,
  schema: GraphQL::Client.load_schema(SCHEMA_DUMP_FILE)
)

# タイトルの情報を取得するGraphQLクエリ
Query = Client.parse <<-GRAPHQL
  query ($databaseId: Int!) {
    title(databaseId: $databaseId) {
      id
      databaseId
      name
      nameKana
      originalMedia
      airedFrom
      airedTo
      episodes {
        edges {
          node {
            id
            identifier
            numberText
            subtitle
          }
        }
      }
    }
  }
GRAPHQL

# GraphQLクエリに与える変数
variables = {
  databaseId: ARGV[0].to_i,
}

# GraphQLクエリの実行
response = Client.query(Query, variables: variables)

# レスポンスの表示
if response.data
  # クエリの実行が行われた場合は response.data に null 以外が返される
  data = response.data
  if data.title
    # フィールドの値の取得に成功している場合の処理

    # タイトル情報の出力
    title = data.title
    title_rows = [
      ['ID', title.id],
      ['データベースID', title.databaseId],
      ['名前', title.name],
      ['よみがな', title.nameKana],
      ['媒体', title.originalMedia],
      ['放送期間', "#{title.airedFrom}〜#{title.airedTo}"],
    ]
    puts Terminal::Table.new(title: 'タイトル情報', rows: title_rows)

    # エピソード情報の出力
    episode_rows = title.episodes.edges.map do |edge|
      episode = edge.node
      [episode.id, episode.identifier, episode.numberText, episode.subtitle]
    end
    puts Terminal::Table.new(title: 'エピソード', headings: %w[ID 識別子 話数 サブタイトル], rows: episode_rows)
  else
    # クエリ実行中にフィールドの値の取得に失敗した場合の処理
    puts "[ERROR] #{data.errors.inspect}"
    exit 1
  end
else
  # クエリ実行前にエラーが発生した場合の処理(無効なアクセストークンなど)
  puts "[ERROR] #{response.errors.inspect}"
  exit 1
end
