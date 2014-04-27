require 'pp'
require 'pocket'
require 'open-uri'
require 'yaml'

require 'bundler/setup'
Bundler.require

yaml = YAML.load_file('config.yaml')
consumer_key = yaml['pocket']['consumer_key']
access_token = yaml['pocket']['access_token']

class DownloadError < RuntimeError
end

def download_image(url)
  file_name = File.basename(url)

  file_name.sub!(%r/\?\w+$/, '') # query parameter
  file_name.sub!(%r/:\w+$/, '') # twitpic ":large"
  file_name = "img/#{file_name}"

  return if File.exist?(file_name)

  open(file_name, 'wb') do |output|
    open(url, allow_redirections: :safe) do |data|
      output.write(data.read)
    end
  end
end

module PicTwitter
  def self.support?(url)
    url.match(%r|^https?://twitter.com/\w+/status/\d+/photo/\d+|)
  end

  def self.image_url(url)
    request_url = url.dup
    request_url.sub!(%r|/$|, '')
    request_url.sub!(%r|/large/?$|, '')
    request_url += '/large'

    doc = Nokogiri::HTML(open(request_url, allow_redirections: :safe))
    img = doc.css('img.large.media-slideshow-image[src]').first

    raise DownloadError unless img && img['src']
    img['src']
  end
end

module Instagram
  def self.support?(url)
    url.match(%r|^https?://instagram.com/p/\w+|)
  end

  def self.image_url(url)
    request_url = url.dup
    request_url.sub!(%r|[/#]$|, '')

    doc = Nokogiri::HTML(open(request_url, allow_redirections: :safe))
    meta = doc.css('meta[property="og:image"]').first

    raise DownloadError unless meta && meta['content']
    meta['content']
  end
end

module Twitpic
  def self.support?(url)
    url.match(%r|^https?://twitpic.com/\w+|)
  end

  def self.image_url(url)
    request_url = url.dup
    request_url.sub!(%r|/$|, '')
    request_url.sub!(%r|/full/?$|, '')
    request_url += '/full'

    doc = Nokogiri::HTML(open(request_url, allow_redirections: :safe))
    img = doc.css('div#media-full > img').first

    raise DownloadError unless img && img['src']
    img['src']
  end
end

# test
# puts PicTwitter.image_url('https://twitter.com/wata_ruh/status/460372514472882176/photo/1')
# puts PicTwitter.image_url('https://twitter.com/wata_ruh/status/460372514472882176/photo/1/')
# puts PicTwitter.image_url('https://twitter.com/wata_ruh/status/460372514472882176/photo/1/large')
# puts PicTwitter.image_url('https://twitter.com/wata_ruh/status/460372514472882176/photo/1/large/')
# puts Instagram.image_url('http://instagram.com/p/nRuMujKpN2')
# puts Instagram.image_url('http://instagram.com/p/nRuMujKpN2#')
# puts Instagram.image_url('http://instagram.com/p/nRuMujKpN2/')
# puts Instagram.image_url('http://instagram.com/p/nRuMujKpN2/#')
# puts Twitpic.image_url('http://twitpic.com/d1ncvp')
# puts Twitpic.image_url('http://twitpic.com/d1ncvp/')
# puts Twitpic.image_url('http://twitpic.com/d1ncvp/full')
# puts Twitpic.image_url('http://twitpic.com/d1ncvp/full/')

Pocket.configure do |config|
  config.consumer_key = consumer_key
end

client = Pocket.client(:access_token => access_token) # session[:access_token]
info = client.retrieve(:detailType => :complete, :count => 200)

info["list"].values.each do |e|
  # puts "#{e['item_id']}, #{e['given_title']}, #{e['resolved_title']}, #{e['resolved_url']}"

  url = e['resolved_url']

  begin
    download_image(PicTwitter.image_url(url)) if PicTwitter.support?(url)
    download_image(Instagram.image_url(url)) if Instagram.support?(url)
    download_image(Twitpic.image_url(url)) if Twitpic.support?(url)
  rescue DownloadError => e
    puts "download failed: #{url}: #{e}"
  rescue OpenURI::HTTPError => e
    puts "http request failed: #{url}: #{e}"
  end
end
