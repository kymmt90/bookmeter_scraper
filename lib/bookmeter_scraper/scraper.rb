require 'mechanize'
require 'yasuri'

require 'bookmeter_scraper/book'
require 'bookmeter_scraper/profile'
require 'bookmeter_scraper/user'

module BookmeterScraper
  class Scraper
    NUM_BOOKS_PER_PAGE = 40
    NUM_USERS_PER_PAGE = 20

    attr_accessor :agent


    def initialize(agent = nil)
      @agent = agent
      @book_pages = {}
    end

    def fetch_profile(user_id, agent = @agent)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      raise ScraperError if agent.nil?

      Profile.new(*scrape_profile(user_id, agent))
    end

    def scrape_profile(user_id, agent)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      raise ScraperError if agent.nil?

      mypage = agent.get(BookmeterScraper.mypage_uri(user_id))

      profile_dl_tags    = mypage.search('#side_left > div.inner > div.profile > dl')
      jp_attribute_names = profile_dl_tags.map { |i| i.children[0].children.text }
      attribute_values   = profile_dl_tags.map { |i| i.children[1].children.text }
      jp_attributes      = Hash[jp_attribute_names.zip(attribute_values)]

      attributes = PROFILE_ATTRIBUTES.map do |attribute|
        jp_attributes[JP_ATTRIBUTE_NAMES[attribute]]
      end
      attributes[0] = mypage.at_css('#side_left > div.inner > h3').text

      attributes
    end

    def fetch_books(user_id, uri_method, agent = @agent)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      raise ArgumentError unless BookmeterScraper.methods.include?(uri_method)
      raise ScraperError if agent.nil?
      return [] unless agent.logged_in?

      books = Books.new
      scraped_pages = scrape_books_pages(user_id, uri_method)
      scraped_pages.each do |page|
        books << extract_books(page)
        books.flatten!
      end
      books
    end

    def scrape_books_pages(user_id, uri_method, agent = @agent)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      raise ArgumentError unless BookmeterScraper.methods.include?(uri_method)
      raise ScraperError if agent.nil?
      return [] unless agent.logged_in?

      books_page = agent.get(BookmeterScraper.method(uri_method).call(user_id))

      # if books are not found at all
      return [] if books_page.search('#main_left > div > center > a').empty?

      if books_page.search('span.now_page').empty?
        books_root = Yasuri.struct_books '//*[@id="main_left"]/div' do
          1.upto(NUM_BOOKS_PER_PAGE) do |i|
            send("text_book_#{i}_name", "//*[@id=\"main_left\"]/div/div[#{i + 1}]/div[2]/a")
            send("text_book_#{i}_link", "//*[@id=\"main_left\"]/div/div[#{i + 1}]/div[2]/a/@href")
          end
        end
        return [books_root.inject(agent, books_page)]
      end

      books_root = Yasuri.pages_root '//span[@class="now_page"]/following-sibling::span[1]/a' do
        text_page_index '//span[@class="now_page"]/a'
        1.upto(NUM_BOOKS_PER_PAGE) do |i|
          send("text_book_#{i}_name", "//*[@id=\"main_left\"]/div/div[#{i + 1}]/div[2]/a")
          send("text_book_#{i}_link", "//*[@id=\"main_left\"]/div/div[#{i + 1}]/div[2]/a/@href")
        end
      end
      books_root.inject(agent, books_page)
    end

    def extract_books(page)
      raise ArgumentError if page.nil?

      books = []
      1.upto(NUM_BOOKS_PER_PAGE) do |i|
        break if page["book_#{i}_link"].empty?

        read_dates = []
        read_date  = scrape_read_date(page["book_#{i}_link"])
        unless read_date.empty?
          read_dates << Time.local(read_date['year'], read_date['month'], read_date['day'])
        end

        reread_dates = []
        reread_dates << scrape_reread_date(page["book_#{i}_link"])
        reread_dates.flatten!

        unless reread_dates.empty?
          reread_dates.each do |date|
            read_dates << Time.local(date['reread_year'], date['reread_month'], date['reread_day'])
          end
        end

        book_path = page["book_#{i}_link"]
        book_name = scrape_book_name(book_path)
        book_author    = scrape_book_author(book_path)
        book_image_uri = scrape_book_image_uri(book_path)
        book = Book.new(book_name,
                        book_author,
                        read_dates,
                        ROOT_URI + book_path,
                        book_image_uri)
        books << book
      end

      books
    end

    def fetch_read_books(user_id, target_year_month)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      raise ArgumentError if target_year_month.nil?

      result = Books.new
      scrape_books_pages(user_id, :read_books_uri).each do |page|
        first_book_date = scrape_read_date(page['book_1_link'])
        last_book_date  = get_last_book_date(page)

        first_book_year_month = Time.local(first_book_date['year'].to_i, first_book_date['month'].to_i)
        last_book_year_month  = Time.local(last_book_date['year'].to_i, last_book_date['month'].to_i)

        if target_year_month < last_book_year_month
          next
        elsif target_year_month == first_book_year_month && target_year_month > last_book_year_month
          result.concat(fetch_target_books(target_year_month, page))
          break
        elsif target_year_month < first_book_year_month && target_year_month > last_book_year_month
          result.concat(fetch_target_books(target_year_month, page))
          break
        elsif target_year_month <= first_book_year_month && target_year_month >= last_book_year_month
          result.concat(fetch_target_books(target_year_month, page))
        elsif target_year_month > first_book_year_month
          break
        end
      end
      result
    end

    def get_last_book_date(page)
      raise ArgumentError if page.nil?

      NUM_BOOKS_PER_PAGE.downto(1) do |i|
        link = page["book_#{i}_link"]
        next if link.empty?
        return scrape_read_date(link)
      end
    end

    def fetch_target_books(target_year_month, page)
      raise ArgumentError if target_year_month.nil?
      raise ArgumentError if page.nil?

      target_books = Books.new
      1.upto(NUM_BOOKS_PER_PAGE) do |i|
        next if page["book_#{i}_link"].empty?

        read_year_months = []
        read_date  = scrape_read_date(page["book_#{i}_link"])
        read_dates = [Time.local(read_date['year'], read_date['month'], read_date['day'])]
        read_year_months << Time.local(read_date['year'], read_date['month'])

        reread_dates = []
        reread_dates << scrape_reread_date(page["book_#{i}_link"])
        reread_dates.flatten!

        unless reread_dates.empty?
          reread_dates.each do |date|
            read_year_months << Time.local(date['reread_year'], date['reread_month'])
          end
        end

        next unless read_year_months.include?(target_year_month)

        unless reread_dates.empty?
          reread_dates.each do |date|
            read_dates << Time.local(date['reread_year'], date['reread_month'], date['reread_day'])
          end
        end
        book_path = page["book_#{i}_link"]
        book_name = scrape_book_name(book_path)
        book_author    = scrape_book_author(book_path)
        book_image_uri = scrape_book_image_uri(book_path)
        target_books << Book.new(book_name, book_author, read_dates, ROOT_URI + book_path, book_image_uri)
      end

      target_books
    end

    def get_book_page(book_uri, agent = @agent)
      @book_pages[book_uri] = agent.get(ROOT_URI + book_uri) unless @book_pages[book_uri]
      @book_pages[book_uri]
    end

    def scrape_book_name(book_uri)
      get_book_page(book_uri).search('#title').text
    end

    def scrape_book_author(book_uri)
      get_book_page(book_uri).search('#author_name').text
    end

    def scrape_book_image_uri(book_uri)
      get_book_page(book_uri).search('//*[@id="book_image"]/@src').text
    end

    def scrape_read_date(book_uri, agent = @agent)
      book_date = Yasuri.struct_date '//*[@id="book_edit_area"]/form[1]/div[2]' do
        text_year  '//*[@id="read_date_y"]/option[1]', truncate: /\d+/, proc: :to_i
        text_month '//*[@id="read_date_m"]/option[1]', truncate: /\d+/, proc: :to_i
        text_day   '//*[@id="read_date_d"]/option[1]', truncate: /\d+/, proc: :to_i
      end
      book_date.inject(agent, get_book_page(book_uri))
    end

    def scrape_reread_date(book_uri, agent = @agent)
      book_reread_date = Yasuri.struct_reread_date '//*[@id="book_edit_area"]/div/form[1]/div[2]' do
        text_reread_year  '//div[@class="reread_box"]/form[1]/div[2]/select[1]/option[1]', truncate: /\d+/, proc: :to_i
        text_reread_month '//div[@class="reread_box"]/form[1]/div[2]/select[2]/option[1]', truncate: /\d+/, proc: :to_i
        text_reread_day   '//div[@class="reread_box"]/form[1]/div[2]/select[3]/option[1]', truncate: /\d+/, proc: :to_i
      end
      book_reread_date.inject(agent, get_book_page(book_uri))
    end

    def fetch_followings(user_id, agent = @agent)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      raise ScraperError if agent.nil?
      return [] unless agent.logged_in?

      users = []
      scraped_pages = user_id == agent.log_in_user_id ? scrape_followings_page(user_id)
                                                      : scrape_others_followings_page(user_id)
      scraped_pages.each do |page|
        users << extract_users(page)
        users.flatten!
      end
      users
    end

    def fetch_followers(user_id, agent = @agent)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      raise ScraperError if agent.nil?
      return [] unless agent.logged_in?

      users = []
      scraped_pages = scrape_followers_page(user_id)
      scraped_pages.each do |page|
        users << extract_users(page)
        users.flatten!
      end
      users
    end

    def scrape_followings_page(user_id, agent = @agent)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      return [] unless agent.logged_in?

      followings_page = agent.get(BookmeterScraper.followings_uri(user_id))
      followings_root = Yasuri.struct_books '//*[@id="main_left"]/div' do
        1.upto(NUM_USERS_PER_PAGE) do |i|
          send("text_user_#{i}_name", "//*[@id=\"main_left\"]/div/div[#{i}]/a/@title")
          send("text_user_#{i}_link", "//*[@id=\"main_left\"]/div/div[#{i}]/a/@href")
        end
      end
      [followings_root.inject(agent, followings_page)]
    end

    def scrape_others_followings_page(user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      scrape_users_listing_page(user_id, :followings_uri)
    end

    def scrape_followers_page(user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      scrape_users_listing_page(user_id, :followers_uri)
    end

    def scrape_users_listing_page(user_id, uri_method, agent = @agent)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      raise ArgumentError unless BookmeterScraper.methods.include?(uri_method)
      return [] unless agent.logged_in?

      page = agent.get(BookmeterScraper.method(uri_method).call(user_id))
      root = Yasuri.struct_users '//*[@id="main_left"]/div' do
        1.upto(NUM_USERS_PER_PAGE) do |i|
          send("text_user_#{i}_name", "//*[@id=\"main_left\"]/div/div[#{i}]/div/div[2]/a/@title")
          send("text_user_#{i}_link", "//*[@id=\"main_left\"]/div/div[#{i}]/div/div[2]/a/@href")
        end
      end
      [root.inject(agent, page)]
    end

    def extract_users(page)
      raise ArgumentError if page.nil?

      users = []
      1.upto(NUM_USERS_PER_PAGE) do |i|
        break if page["user_#{i}_name"].empty?

        user_name = page["user_#{i}_name"]
        user_id   = page["user_#{i}_link"].match(/\/u\/(\d+)$/)[1]
        users << User.new(user_name, user_id, ROOT_URI + "/u/#{user_id}")
      end

      users
    end
  end

  class ScraperError < StandardError; end
end
