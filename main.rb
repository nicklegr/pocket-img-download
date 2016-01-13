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

  file_name.sub!(%r/\?.+$/, '') # query parameter
  file_name.sub!(%r/:\w+$/, '') # pic.twitter.com ":orig"
  file_name = "img/#{file_name}"

  return if File.exist?(file_name)

  open(file_name, 'wb') do |output|
    open(url, allow_redirections: :safe) do |data|
      output.write(data.read)
    end
  end

  if File.size(file_name) == 0
    File.delete(file_name)
    raise DownloadError 
  end
end

module PicTwitter
  def self.support?(url)
    url.match(%r|^https?://twitter.com/\w+/status/\d+/photo/\d+|)
  end

  def self.image_urls(url)
    doc = Nokogiri::HTML(open(url, allow_redirections: :safe))

    img_urls = []

    doc.css('div.js-adaptive-photo').each do |div|
      img_urls << div['data-image-url']
    end

    img_urls.map! do |e|
      e.sub(%r/:\w+$/, '') + ":orig"
    end

    raise DownloadError if img_urls.empty?

    img_urls
  end
end

module Instagram
  def self.support?(url)
    url.match(%r|^https?://instagram.com/p/\w+|)
  end

  def self.image_urls(url)
    request_url = url.dup
    request_url.sub!(%r|[/#]$|, '')

    doc = Nokogiri::HTML(open(request_url, allow_redirections: :safe))
    meta = doc.css('meta[property="og:image"]').first

    raise DownloadError unless meta && meta['content']
    [ meta['content'] ]
  end
end

module Twitpic
  def self.support?(url)
    url.match(%r|^https?://twitpic.com/\w+|)
  end

  def self.image_urls(url)
    request_url = url.dup
    request_url.sub!(%r|/$|, '')
    request_url.sub!(%r|/full/?$|, '')

    doc = Nokogiri::HTML(open(request_url, allow_redirections: :safe))
    img = doc.css('div#media > img').first

    raise DownloadError unless img && img['src']
    [ img['src'] ]
  end
end

# test
# puts PicTwitter.image_urls('https://twitter.com/wata_ruh/status/460372514472882176/photo/1')
# puts PicTwitter.image_urls('https://twitter.com/wata_ruh/status/460372514472882176/photo/1/')
# puts PicTwitter.image_urls('https://twitter.com/wata_ruh/status/460372514472882176/photo/1/large')
# puts PicTwitter.image_urls('https://twitter.com/wata_ruh/status/460372514472882176/photo/1/large/')
# puts PicTwitter.image_urls('http://twitter.com/tamamapapa/status/686947569222586368/photo/1')
# puts Instagram.image_urls('http://instagram.com/p/nRuMujKpN2')
# puts Instagram.image_urls('http://instagram.com/p/nRuMujKpN2#')
# puts Instagram.image_urls('http://instagram.com/p/nRuMujKpN2/')
# puts Instagram.image_urls('http://instagram.com/p/nRuMujKpN2/#')
# puts Twitpic.image_urls('http://twitpic.com/d1ncvp')
# puts Twitpic.image_urls('http://twitpic.com/d1ncvp/')
# puts Twitpic.image_urls('http://twitpic.com/d1ncvp/full')
# puts Twitpic.image_urls('http://twitpic.com/d1ncvp/full/')

# download_image(Twitpic.image_url('http://twitpic.com/d1ncvp/full/'))

# PicTwitter.image_urls('https://twitter.com/wata_ruh/status/460372514472882176/photo/1').each do |e|
#   puts e
#   download_image(e)
# end

# PicTwitter.image_urls('http://twitter.com/ToMeto_M/status/535433969227935744/photo/1').each do |e|
#   puts e
#   download_image(e)
# end

# exit

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
