# coding: utf-8

require 'open-uri'

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
