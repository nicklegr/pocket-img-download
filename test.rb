# coding: utf-8

require_relative "download"
require_relative "services"

# test
puts PicTwitter.image_urls('https://twitter.com/wata_ruh/status/460372514472882176/photo/1')
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
