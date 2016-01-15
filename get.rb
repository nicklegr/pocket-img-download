# coding: utf-8

require_relative "download"

ARGV.each do |e|
  download(e)
end
