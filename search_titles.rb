#!/usr/bin/env ruby

require 'active_support'
require 'active_support/core_ext'
require 'graphql/client'
require 'graphql/client/http'
require 'terminal-table'

GRAPHQL_ENDPOINT = 'https://api.qnyp.com/graphql'.freeze
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

# タイトルを検索するGraphQLクエリ
Query = Client.parse <<-GRAPHQL
  query($query: String!, $first: Int!) {
    searchTitles(
      query: $query,
      orderBy: { field: AIRED_DATE, direction: DESC },
      first: $first
    ) {
      totalCount
      pageInfo {
        hasNextPage
      }
      edges {
        node {
          id
          databaseId
          name
          airedFrom
          originalMedia
          episodes {
            totalCount
          }
        }
      }
    }
  }
GRAPHQL

# GraphQLクエリに与える変数
variables = {
  query: ARGV[0].try(:strip),
  first: 20,
}

# GraphQLクエリの実行
response = Client.query(Query, variables: variables)

# レスポンスの表示
if response.data
  # クエリの実行が行われた場合は response.data に null 以外が返される
  data = response.data
  if data.searchTitles
    # フィールドの値の取得に成功している場合の処理
    has_next_page = data.searchTitles.pageInfo.hasNextPage
    total_count = data.searchTitles.totalCount
    titles = data.searchTitles.edges.map(&:node)

    rows = titles.map do |title|
      [
        title.id,
        title.name,
        title.airedFrom,
        title.originalMedia,
        title.episodes.totalCount,
      ]
    end

    table = Terminal::Table.new(
      headings: %w[ID 名前 放送開始日 媒体 エピソード数],
      rows: rows
    )
    if has_next_page
      puts "該当する#{total_count}件のうち20件を表示します。"
    else
      puts "該当する#{total_count}件を表示します。"
    end
    puts table
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
