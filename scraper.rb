#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

# require 'open-uri/cached'
# OpenURI::Cache.cache_path = '.cache'
require 'scraped_page_archive/open-uri'

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)

  noko.css('#ctl00_ContentPlaceHolder1_GridView1 table a').to_a.uniq { |n| n.attr('href') }.each do |a|
    # too many variations in layout on these pages to usefully scrape... loading them just to archive
    link = URI.join(url, a.attr('href')).to_s
    member_page = open(link)

    data = {
      id:     link[/Id=(\d+)/, 1],
      name:   a.text.tidy,
      image:  a.xpath('following::img[contains(@src,"Images")][1]/@src').text,
      term:   2010,
      source: url.to_s,
    }
    ScraperWiki.save_sqlite(%i(id term), data)
  end

  unless (next_page = noko.css('a#ctl00_ContentPlaceHolder1_lnkNextPage/@href')).empty?
    scrape_list(URI.join(url, next_page.text))
  end
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('http://wolesi.website/pve/document.aspx?Cat=37')
