# coding: utf-8

require 'pp'
require 'pocket'
require 'open-uri'
require 'yaml'

require 'bundler/setup'
Bundler.require

require_relative "download"
require_relative "services"

yaml = YAML.load_file('config.yaml')
consumer_key = yaml['pocket']['consumer_key']
access_token = yaml['pocket']['access_token']

Pocket.configure do |config|
  config.consumer_key = consumer_key
end

client = Pocket.client(:access_token => access_token) # session[:access_token]
info = client.retrieve(:detailType => :complete, :count => 200)

info["list"].values.each do |e|
  # puts "#{e['item_id']}, #{e['given_title']}, #{e['resolved_title']}, #{e['resolved_url']}"

  url = e['resolved_url']
  next unless url
  # puts url

  begin
    if download(url)
      # puts "modify #{e['item_id']}"
      client.modify([ { action: 'archive', item_id: e['item_id'] } ])
    end
  rescue DownloadError => e
    puts "download failed: #{url}: #{e}"
  rescue OpenURI::HTTPError => e
    puts "http request failed: #{url}: #{e}"
  end
end
