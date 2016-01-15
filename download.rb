# coding: utf-8

require 'open-uri'

require_relative "exception"
require_relative "services"

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

def download(url)
  if PicTwitter.support?(url)
    PicTwitter.image_urls(url).each do |img_url|
      download_image(img_url)
    end
    return true
  end

  if Instagram.support?(url)
    Instagram.image_urls(url).each do |img_url|
      download_image(img_url)
    end
    return true
  end

  if Twitpic.support?(url)
    Twitpic.image_urls(url).each do |img_url|
      download_image(img_url)
    end
    return true
  end

  false
end
