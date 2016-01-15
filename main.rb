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
    downloaded = false

    if PicTwitter.support?(url)
      PicTwitter.image_urls(url).each do |img_url|
        download_image(img_url)
      end
      downloaded = true
    end

    if Instagram.support?(url)
      Instagram.image_urls(url).each do |img_url|
        download_image(img_url)
      end
      downloaded = true
    end

    if Twitpic.support?(url)
      Twitpic.image_urls(url).each do |img_url|
        download_image(img_url)
      end
      downloaded = true
    end

    if downloaded
      # puts "modify #{e['item_id']}"
      client.modify([ { action: 'archive', item_id: e['item_id'] } ])
    end
  rescue DownloadError => e
    puts "download failed: #{url}: #{e}"
  rescue OpenURI::HTTPError => e
    puts "http request failed: #{url}: #{e}"
  end
end
