# encoding: UTF-8
# frozen_string_literal: true

#
# Convert regular logfile into something else:
#   cat logfile.log | grep "Scraping Page" | cut -d ":" -f 4 | cut -d " " -f 4 > pages.log
#   -> 2 is the first word
#   -> cut is 1-indexed

require 'nokogiri'
require 'open-uri'
require 'awesome_print'
require 'curb'
require 'oj'
require 'oj_mimic_json'
require 'parallel'
require 'logger'

$logger = Logger.new('logfile.log')

require_relative 'result_tracker'
require_relative 'btc_balance'
require_relative 'page_navigator'

class BitcoinScraper
  attr_accessor :page_navigator, :result_tracker

  def initialize(starting_page = nil)
    self.page_navigator = PageNavigator.new(starting_page)
    self.result_tracker = ResultTracker.new
  end

  def search!
    find_keys while result_tracker.captured.size < 50
  rescue SystemExit, Interrupt => e
    ap e
    result_tracker.print_summary
    raise
  end

  private

  def check_btc(address, private_key)
    balance = BTC_BALANCE.get(address)

    has_money = balance > 0

    return unless has_money

    ap "found BTC #{balance} at #{address}!"

    result_tracker.capture(address, private_key, balance, 'btc')
  end

  def print_status
    ap "Scanned #{page_navigator.scanned_pages} pages and found #{result_tracker.captured.size} this session"

    $logger.info "Scraping Page #{page_navigator.current_page}..."
    $logger.info "Currently: #{result_tracker.captured.size}"

    ap result_tracker.captured unless result_tracker.captured.empty?
  end

  def find_keys
    print_status

    doc = page_navigator.next_page

    comprimised_keys = doc.css('pre > lol')

    comprimised_keys.each do |node|
      private_key = node.css('lol').text.strip
      address = node.css('a + a').text.strip

      check_btc(address, private_key)
      # check_bcc(address, private_key)
    end
  end
end

# PROCESSES = 16
# Parallel.each(Array.new(PROCESSES), in_processes: PROCESSES) do |_|
scraper = BitcoinScraper.new
scraper.search!
# end
# ap scraper.send(:check_btc, '3D2oetdNuZUqQHPJmcMDDHYoqkyNVsFk9r', 'test')
