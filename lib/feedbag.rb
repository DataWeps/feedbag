#!/usr/bin/ruby

# Copyright (c) 2008-2014 David Moreno <david@axiombox.com>
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

require "rubygems"
require "nokogiri"
require "open-uri"
require "net/http"
require "open_uri_redirections"

class Feedbag

  CONTENT_TYPES = [
    'application/x.atom+xml',
    'application/atom+xml',
    'application/xml',
    'text/xml',
    'application/rss+xml',
    'application/rdf+xml',
    'application/json',   
  ].freeze

  def self.feed?(url)
    new.feed?(url)
  end

  def self.find(url, args = {})
    new.find(url, args = {})
  end

  def initialize
    @feeds = []
  end

  def feed?(url)
    # use LWR::Simple.normalize some time
    url_uri = URI.parse(url)
    url = "#{url_uri.scheme or 'http'}://#{url_uri.host}#{url_uri.path}"
    url << "?#{url_uri.query}" if url_uri.query

      # hack:
      url.sub!(/^feed:\/\//, 'http://')

    res = Feedbag.find(url)
    if res.size == 1 and res.first == url
      return true
    else
      return false
    end
  end

  def find(url, args = {})
    url_uri = URI.parse(url)
    url = nil
    if url_uri.scheme.nil?
      url = "http://#{url_uri.to_s}"
    elsif url_uri.scheme == "feed"
      return self.add_feed(url_uri.to_s.sub(/^feed:\/\//, 'http://'), nil)
    else
      url = url_uri.to_s
    end
    #url = "#{url_uri.scheme or 'http'}://#{url_uri.host}#{url_uri.path}"

    # check if feed_valid is avail
    begin
      require "feed_validator"
      v = W3C::FeedValidator.new
      v.validate_url(url)
      return self.add_feed(url, nil) if v.valid?
    rescue LoadError
      # scoo
    rescue REXML::ParseException
      # usually indicates timeout
      # TODO: actually find out timeout. use Terminator?
      # $stderr.puts "Feed looked like feed but might not have passed validation or timed out"
    rescue => ex
      $stderr.puts "#{ex.class} error occurred with: `#{url}': #{ex.message}"
    end

    self.add_feed(url, nil)
  end

  def add_feed(feed_url, orig_url, base_uri = nil)
    # puts "#{feed_url} - #{orig_url}"
    url = feed_url.sub(/^feed:/, '').strip

    if base_uri
      #	url = base_uri + feed_url
      url = URI.parse(base_uri).merge(feed_url).to_s
    end

    begin
      uri = URI.parse(url)
    rescue
      puts "Error with `#{url}'"
      exit 1
    end
    unless uri.absolute?
      orig = URI.parse(orig_url)
      url = orig.merge(url).to_s
    end

    # verify url is really valid
    @feeds.push(url) unless @feeds.include?(url)# if self._is_http_valid(URI.parse(url), orig_url)
  end

  # not used. yet.
  def _is_http_valid(uri, orig_url)
    req = Net::HTTP.get_response(uri)
    orig_uri = URI.parse(orig_url)
    case req
    when Net::HTTPSuccess then
      return true
    else
      return false
    end
  end
end

if __FILE__ == $0
  if ARGV.size == 0
    puts 'usage: feedbag url'
  else
    puts Feedbag.find ARGV.first
  end
end
