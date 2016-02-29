require 'forwardable'
require 'mechanize'
require 'yasuri'

module BookmeterScraper
  class Bookmeter
    ROOT_URI  = 'http://bookmeter.com'.freeze
    LOGIN_URI = "#{ROOT_URI}/login".freeze

    PROFILE_ATTRIBUTES = %i(name gender age blood_type job address url description first_day elapsed_days read_books_count read_pages_count reviews_count bookshelfs_count)
    Profile = Struct.new(*PROFILE_ATTRIBUTES)

    BOOK_ATTRIBUTES = %i(name author read_dates)
    Book = Struct.new(*BOOK_ATTRIBUTES)
    class Books
      extend Forwardable

      def_delegator :@books, :[]
      def_delegator :@books, :[]=
      def_delegator :@books, :<<
      def_delegator :@books, :each
      def_delegator :@books, :flatten!

      def initialize; @books = []; end

      def concat(books)
        books.each do |book|
          next if @books.any? { |b| b.name == book.name && b.author == book.author }
          @books << book
        end
      end

      def to_a; @books; end
    end

    USER_ATTRIBUTES = %i(name id)
    User = Struct.new(*USER_ATTRIBUTES)

    JP_ATTRIBUTE_NAMES = {
      gender: '性別',
      age: '年齢',
      blood_type: '血液型',
      job: '職業',
      address: '現住所',
      url: 'URL / ブログ',
      description: '自己紹介',
      first_day: '記録初日',
      elapsed_days: '経過日数',
      read_books_count: '読んだ本',
      read_pages_count: '読んだページ',
      reviews_count: '感想/レビュー',
      bookshelfs_count: '本棚',
    }

    NUM_BOOKS_PER_PAGE = 40
    NUM_USERS_PER_PAGE = 20

    attr_reader :log_in_user_id

    def self.mypage_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}"
    end

    def self.read_books_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/booklist"
    end

    def self.reading_books_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/booklistnow"
    end

    def self.tsundoku_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/booklisttun"
    end

    def self.wish_list_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/booklistpre"
    end

    def self.followings_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/favorite_user"
    end

    def self.followers_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/favorited_user"
    end

    def self.log_in(mail, password)
      Bookmeter.new.tap do |bookmeter|
        bookmeter.log_in(mail, password)
      end
    end


    def initialize(agent = nil)
      @agent = agent.nil? ? Bookmeter.new_agent : agent
      @logged_in = false
      @book_pages = {}
    end

    def log_in(mail, password)
      raise BookmeterError if @agent.nil?

      next_page = nil
      page = @agent.get(LOGIN_URI) do |page|
        next_page = page.form_with(action: '/login') do |form|
          form.field_with(name: 'mail').value = mail
          form.field_with(name: 'password').value = password
        end.submit
      end
      @logged_in = next_page.uri.to_s == ROOT_URI + '/'
      return unless logged_in?

      mypage = next_page.link_with(text: 'マイページ').click
      @log_in_user_id = extract_user_id(mypage)
    end

    def logged_in?
      @logged_in
    end

    def profile(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/

      mypage = @agent.get(Bookmeter.mypage_uri(user_id))

      profile_dl_tags = mypage.search('#side_left > div.inner > div.profile > dl')
      jp_attribute_names = profile_dl_tags.map { |i| i.children[0].children.text }
      attribute_values   = profile_dl_tags.map { |i| i.children[1].children.text }
      jp_attributes = Hash[jp_attribute_names.zip(attribute_values)]
      attributes = PROFILE_ATTRIBUTES.map do |attribute|
        jp_attributes[JP_ATTRIBUTE_NAMES[attribute]]
      end
      attributes[0] = mypage.at_css('#side_left > div.inner > h3').text

      Profile.new(*attributes)
    end

    def read_books(user_id = @log_in_user_id)
      books = get_books(user_id, :read_books_uri)
      books.each { |b| yield b } if block_given?
      books.to_a
    end

    def read_books_in(year, month, user_id = @log_in_user_id)
      date = Time.local(year, month)
      books = get_read_books(user_id, date)
      books.each { |b| yield b } if block_given?
      books.to_a
    end

    def reading_books(user_id = @log_in_user_id)
      books = get_books(user_id, :reading_books_uri)
      books.each { |b| yield b } if block_given?
      books.to_a
    end

    def tsundoku(user_id = @log_in_user_id)
      books = get_books(user_id, :tsundoku_uri)
      books.each { |b| yield b } if block_given?
      books.to_a
    end

    def wish_list(user_id = @log_in_user_id)
      books = get_books(user_id, :wish_list_uri)
      books.each { |b| yield b } if block_given?
      books.to_a
    end

    def followings(user_id = @log_in_user_id)
      users = get_followings(user_id)
    end

    def followers(user_id = @log_in_user_id)
      users = get_followers(user_id)
    end

    private

    def self.new_agent
      agent = Mechanize.new do |a|
        a.user_agent_alias = 'Mac Safari'
      end
    end

    def extract_user_id(page)
      page.uri.to_s.match(/\/u\/(\d+)$/)[1]
    end

    def get_books(user_id, uri_method)
      books = Books.new
      scraped_pages = scrape_book_pages(user_id, uri_method)
      scraped_pages.each do |page|
        books << get_book_structs(page)
        books.flatten!
      end
      books
    end

    def get_read_books(user_id, target_ym)
      result = Books.new
      scrape_book_pages(user_id, :read_books_uri).each do |page|
        first_book_date = get_read_date(page['book_1_link'])
        last_book_date  = get_last_book_date(page)

        first_book_ym = Time.local(first_book_date['year'].to_i, first_book_date['month'].to_i)
        last_book_ym  = Time.local(last_book_date['year'].to_i, last_book_date['month'].to_i)

        if target_ym < last_book_ym
          next
        elsif target_ym == first_book_ym && target_ym > last_book_ym
          result.concat(get_target_books(target_ym, page))
          break
        elsif target_ym < first_book_ym && target_ym > last_book_ym
          result.concat(get_target_books(target_ym, page))
          break
        elsif target_ym <= first_book_ym && target_ym >= last_book_ym
          result.concat(get_target_books(target_ym, page))
        elsif target_ym > first_book_ym
          break
        end
      end
      result
    end

    def get_last_book_date(page)
      NUM_BOOKS_PER_PAGE.downto(1) do |i|
        link = page["book_#{i}_link"]
        next if link.empty?
        return get_read_date(link)
      end
    end

    def get_target_books(target_ym, page)
      target_books = Books.new

      1.upto(NUM_BOOKS_PER_PAGE) do |i|
        next if page["book_#{i}_link"].empty?

        read_yms = []
        read_date = get_read_date(page["book_#{i}_link"])
        read_dates = [Time.local(read_date['year'], read_date['month'], read_date['day'])]
        read_yms << Time.local(read_date['year'], read_date['month'])

        reread_dates = []
        reread_dates << get_reread_date(page["book_#{i}_link"])
        reread_dates.flatten!

        unless reread_dates.empty?
          reread_dates.each do |date|
            read_yms << Time.local(date['reread_year'], date['reread_month'])
          end
        end

        next unless read_yms.include?(target_ym)

        unless reread_dates.empty?
          reread_dates.each do |date|
            read_dates << Time.local(date['reread_year'], date['reread_month'], date['reread_day'])
          end
        end
        book_name = get_book_name(page["book_#{i}_link"])
        book_author = get_book_author(page["book_#{i}_link"])
        book = Book.new(book_name, book_author, read_dates)
        target_books << book
      end

      target_books
    end

    def scrape_book_pages(user_id, uri_method)
      raise ArgumentError unless user_id =~ /^\d+$/
      raise ArgumentError unless Bookmeter.methods.include?(uri_method)
      return [] unless logged_in?

      books_page = @agent.get(Bookmeter.method(uri_method).call(user_id))

      # if books are not found at all
      return [] if books_page.search('#main_left > div > center > a').empty?

      if books_page.search('span.now_page').empty?
        books_root = Yasuri.struct_books '//*[@id="main_left"]/div' do
          1.upto(NUM_BOOKS_PER_PAGE) do |i|
            send("text_book_#{i}_name", "//*[@id=\"main_left\"]/div/div[#{i + 1}]/div[2]/a")
            send("text_book_#{i}_link", "//*[@id=\"main_left\"]/div/div[#{i + 1}]/div[2]/a/@href")
          end
        end
        return [books_root.inject(@agent, books_page)]
      end

      books_root = Yasuri.pages_root '//span[@class="now_page"]/following-sibling::span[1]/a' do
        text_page_index '//span[@class="now_page"]/a'
        1.upto(NUM_BOOKS_PER_PAGE) do |i|
          send("text_book_#{i}_name", "//*[@id=\"main_left\"]/div/div[#{i + 1}]/div[2]/a")
          send("text_book_#{i}_link", "//*[@id=\"main_left\"]/div/div[#{i + 1}]/div[2]/a/@href")
        end
      end
      books_root.inject(@agent, books_page)
    end

    def get_book_page(book_uri)
      @book_pages[book_uri] = @agent.get(ROOT_URI + book_uri) unless @book_pages[book_uri]
      @book_pages[book_uri]
    end

    def get_book_name(book_uri)
      get_book_page(book_uri).search('#title').text
    end

    def get_book_author(book_uri)
      get_book_page(book_uri).search('#author_name').text
    end

    def get_read_date(book_uri)
      book_date = Yasuri.struct_date '//*[@id="book_edit_area"]/form[1]/div[2]' do
        text_year  '//*[@id="read_date_y"]/option[1]', truncate: /\d+/, proc: :to_i
        text_month '//*[@id="read_date_m"]/option[1]', truncate: /\d+/, proc: :to_i
        text_day   '//*[@id="read_date_d"]/option[1]', truncate: /\d+/, proc: :to_i
      end
      book_date.inject(@agent, get_book_page(book_uri))
    end

    def get_reread_date(book_uri)
      book_reread_date = Yasuri.struct_reread_date '//*[@id="book_edit_area"]/div/form[1]/div[2]' do
        text_reread_year  '//div[@class="reread_box"]/form[1]/div[2]/select[1]/option[1]', truncate: /\d+/, proc: :to_i
        text_reread_month '//div[@class="reread_box"]/form[1]/div[2]/select[2]/option[1]', truncate: /\d+/, proc: :to_i
        text_reread_day   '//div[@class="reread_box"]/form[1]/div[2]/select[3]/option[1]', truncate: /\d+/, proc: :to_i
      end
      book_reread_date.inject(@agent, get_book_page(book_uri))
    end

    def get_book_structs(page)
      books = []

      1.upto(NUM_BOOKS_PER_PAGE) do |i|
        break if page["book_#{i}_link"].empty?

        read_dates = []
        read_date = get_read_date(page["book_#{i}_link"])
        unless read_date.empty?
          read_dates << Time.local(read_date['year'], read_date['month'], read_date['day'])
        end

        reread_dates = []
        reread_dates << get_reread_date(page["book_#{i}_link"])
        reread_dates.flatten!

        unless reread_dates.empty?
          reread_dates.each do |date|
            read_dates << Time.local(date['reread_year'], date['reread_month'], date['reread_day'])
          end
        end

        book_name = get_book_name(page["book_#{i}_link"])
        book_author = get_book_author(page["book_#{i}_link"])
        book = Book.new(book_name, book_author, read_dates)
        books << book
      end

      books
    end

    def get_followings(user_id)
      users = []
      scraped_pages = user_id == @log_in_user_id ? scrape_followings_page(user_id)
                                                 : scrape_others_followings_page(user_id)
      scraped_pages.each do |page|
        users << get_user_structs(page)
        users.flatten!
      end
      users
    end

    def get_followers(user_id)
      users = []
      scraped_pages = scrape_followers_page(user_id)
      scraped_pages.each do |page|
        users << get_user_structs(page)
        users.flatten!
      end
      users
    end

    def get_user_structs(page)
      users = []

      1.upto(NUM_USERS_PER_PAGE) do |i|
        break if page["user_#{i}_name"].empty?

        user_name = page["user_#{i}_name"]
        user_id = page["user_#{i}_link"].match(/\/u\/(\d+)$/)[1]
        user = User.new(user_name, user_id)
        users << user
      end

      users
    end

    def scrape_followings_page(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      return [] unless logged_in?

      followings_page = @agent.get(Bookmeter.followings_uri(user_id))
      followings_root = Yasuri.struct_books '//*[@id="main_left"]/div' do
        1.upto(NUM_USERS_PER_PAGE) do |i|
          send("text_user_#{i}_name", "//*[@id=\"main_left\"]/div/div[#{i}]/a/@title")
          send("text_user_#{i}_link", "//*[@id=\"main_left\"]/div/div[#{i}]/a/@href")
        end
      end
      [followings_root.inject(@agent, followings_page)]
    end

    def scrape_others_followings_page(user_id)
      scrape_users_listing_page(user_id, :followings_uri)
    end

    def scrape_followers_page(user_id)
      scrape_users_listing_page(user_id, :followers_uri)
    end

    def scrape_users_listing_page(user_id, uri_method)
      raise ArgumentError unless user_id =~ /^\d+$/
      raise ArgumentError unless Bookmeter.methods.include?(uri_method)
      return [] unless logged_in?

      page = @agent.get(Bookmeter.method(uri_method).call(user_id))
      root = Yasuri.struct_users '//*[@id="main_left"]/div' do
        1.upto(NUM_USERS_PER_PAGE) do |i|
          send("text_user_#{i}_name", "//*[@id=\"main_left\"]/div/div[#{i}]/div/div[2]/a/@title")
          send("text_user_#{i}_link", "//*[@id=\"main_left\"]/div/div[#{i}]/div/div[2]/a/@href")
        end
      end
      [root.inject(@agent, page)]
    end
  end

  class BookmeterError < StandardError; end
end
