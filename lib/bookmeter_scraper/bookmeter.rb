require 'mechanize'
require 'yasuri'

module BookmeterScraper
  class Bookmeter
    ROOT_URI  = 'http://bookmeter.com'.freeze
    LOGIN_URI = "#{ROOT_URI}/login".freeze

    PROFILE_ATTRIBUTES = %i(name gender age blood_type job address url description first_day elapsed_days read_books_count read_pages_count reviews_count bookshelfs_count)
    Profile = Struct.new(*PROFILE_ATTRIBUTES)

    BOOK_ATTRIBUTES = %i(name read_dates)
    Book = Struct.new(*BOOK_ATTRIBUTES)

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

    def self.log_in(mail, password)
      Bookmeter.new.tap do |bookmeter|
        bookmeter.log_in(mail, password)
      end
    end


    def initialize(agent = nil)
      @agent = agent.nil? ? Bookmeter.new_agent : agent
      @logged_in = false
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

    def read_books(user_id)
      get_books(user_id, :read_books_uri)
    end

    def reading_books(user_id)
      get_books(user_id, :reading_books_uri)
    end

    def tsundoku(user_id)
      get_books(user_id, :tsundoku_uri)
    end

    def wish_list(user_id)
      get_books(user_id, :wish_list_uri)
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
      books = []
      scraped_pages = scrape_book_pages(user_id, uri_method)
      scraped_pages.each do |page|
        books << get_book_structs(@agent, page)
        books.flatten!
      end
      books
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

    def get_book_name(book_link)
      @agent.get(ROOT_URI + book_link).search('#title').text
    end

    def get_read_date(agent, book_link)
      book_page = agent.get(ROOT_URI + book_link)
      book_date = Yasuri.struct_date '//*[@id="book_edit_area"]/form[1]/div[2]' do
        text_year  '//*[@id="read_date_y"]/option[1]', truncate: /\d+/, proc: :to_i
        text_month '//*[@id="read_date_m"]/option[1]', truncate: /\d+/, proc: :to_i
        text_day   '//*[@id="read_date_d"]/option[1]', truncate: /\d+/, proc: :to_i
      end
      book_date.inject(agent, book_page)
    end

    def get_reread_date(agent, book_link)
      book_page = agent.get(ROOT_URI + book_link)
      book_reread_date = Yasuri.struct_reread_date '//*[@id="book_edit_area"]/div/form[1]/div[2]' do
        text_reread_year  '//div[@class="reread_box"]/form[1]/div[2]/select[1]/option[1]', truncate: /\d+/, proc: :to_i
        text_reread_month '//div[@class="reread_box"]/form[1]/div[2]/select[2]/option[1]', truncate: /\d+/, proc: :to_i
        text_reread_day   '//div[@class="reread_box"]/form[1]/div[2]/select[3]/option[1]', truncate: /\d+/, proc: :to_i
      end
      book_reread_date.inject(agent, book_page)
    end

    def get_book_structs(agent, page)
      books = []

      1.upto(NUM_BOOKS_PER_PAGE) do |i|
        break if page["book_#{i}_link"].empty?

        read_dates = []
        read_date = get_read_date(agent, page["book_#{i}_link"])
        unless read_date.empty?
          read_dates << Time.local(read_date['year'], read_date['month'], read_date['day'])
        end

        reread_dates = []
        reread_dates << get_reread_date(agent, page["book_#{i}_link"])
        reread_dates.flatten!

        unless reread_dates.empty?
          reread_dates.each do |date|
            read_dates << Time.local(date['reread_year'], date['reread_month'], date['reread_day'])
          end
        end

        book_name = get_book_name(page["book_#{i}_link"])
        book = Book.new(book_name, read_dates)
        books << book
      end

      books
    end
  end

  class BookmeterError < StandardError; end
end
