class PageNavigator
  DB = 'http://directory.io'.freeze
  NUMBER_OF_KEYS = 904_625_697_166_532_776_746_648_320_380_374_280_100_293_470_930_272_690_489_102_837_043_110_636_675
  NUMBER_OF_PAGES = NUMBER_OF_KEYS / 256
  OPEN_OPTIONS = {
    'User-Agent' => 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36'
  }.freeze

  LOG_NAME = 'pages.log'

  attr_accessor :starting_page,
                :pages_logger,
                :visited_pages,
                :scanned_pages,
                :current_page

  def initialize(starting_page = nil)
    self.current_page = starting_page || 0
    self.starting_page = starting_page || 0
    self.pages_logger = Logger.new(LOG_NAME)
    pages_logger.formatter = proc do |_severity, _datetime, _progname, _msg|
      "{msg}\n"
    end

    self.visited_pages = []
    load_visited_pages

    self.scanned_pages = 0
  end

  def next_page(sequential = false)
    to_page(next_page_number(sequential))
  end

  def next_page_number(sequential = false)
    number = sequential ? current_page + 1 : rand(NUMBER_OF_PAGES)

    visited?(number) ? next_page_number(sequential) : number
  end

  def to_page(page, attempts = 0)
    html = Nokogiri::HTML(open("#{DB}/#{page}", OPEN_OPTIONS), nil, Encoding::UTF_8.to_s)
    make_note_of_visited_page(page)
    html
  rescue => e
    ap e

    raise unless attempts < 10
    sleep(1000 + rand(10_000))
    to_page(page, attempts + 1)
  end

  private

  def load_visited_pages
    self.visited_pages = File.readlines(LOG_NAME)

    size = visited_pages.size
    ap "there have been #{size} pages / #{size * 256} addresses scanned so far"
  end

  def make_note_of_visited_page(page_number)
    pages_logger.info(page_number)
    visited_pages.push(page_number)
    self.current_page = page_number
    visited_pages.push(page_number)
    self.scanned_pages += 1

  end

  def visited?(page)
    visited_pages.include?(page.to_s)
  end
end
