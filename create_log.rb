#!/usr/bin/env ruby

require 'active_support'
require 'active_support/core_ext'
require 'graphql/client'
require 'graphql/client/http'

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

# 視聴ログを作成するGraphQL mutation
CreateLogMutation = Client.parse <<-GRAPHQL
  mutation ($input: CreateLogInput!) {
    createLog(input: $input) {
      log {
        id
        databaseId
        createdAt
        body
        rating
        user {
          username
        }
        episode {
          subtitle
        }
        url
      }
    }
  }
GRAPHQL

# GraphQLクエリに与える変数
variables = {
  input: {
    episodeId: ARGV[0],
    rating: ARGV[1],
    channel: 'NONE',
    spoiler: false,
  },
}
variables[:input][:body] = ARGV[2] if ARGV[2].present?

# GraphQL mutationの実行
response = Client.query(CreateLogMutation, variables: variables)

# レスポンスの表示
if response.data
  # mutationの実行が行われた場合は response.data に null 以外が返される
  data = response.data
  if data.createLog && data.createLog.log
    # フィールドの値の取得に成功している場合の処理

    # 視聴ログ情報の出力
    log = data.createLog.log
    puts "id: #{log.id}"
    puts "databaeId: #{log.databaseId}"
    puts "createdAt: #{log.createdAt}"
    puts "body: #{log.body}"
    puts "rating: #{log.rating}"
    puts "user.username: #{log.user.username}"
    puts "episode.subtitle: #{log.episode.subtitle}"
    puts "url: #{log.url}"
  else
    # フィールドの値の取得に失敗した場合の処理
    puts "[ERROR] #{data.errors.inspect}"
    exit 1
  end
else
  # mutation実行前にエラーが発生した場合の処理(無効なアクセストークンなど)
  puts "[ERROR] #{response.errors.inspect}"
  exit 1
end
