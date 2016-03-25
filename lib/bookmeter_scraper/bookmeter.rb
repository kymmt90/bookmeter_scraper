require 'forwardable'
require 'yasuri'

module BookmeterScraper
  ROOT_URI  = 'http://bookmeter.com'.freeze
  LOGIN_URI = "#{BookmeterScraper::ROOT_URI}/login".freeze

  class << self
    def mypage_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}"
    end

    def read_books_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/booklist"
    end

    def reading_books_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/booklistnow"
    end

    def tsundoku_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/booklisttun"
    end

    def wish_list_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/booklistpre"
    end

    def followings_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/favorite_user"
    end

    def followers_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/favorited_user"
    end
  end

  class Bookmeter
    DEFAULT_CONFIG_PATH = './config.yml'.freeze

    attr_reader :log_in_user_id


    class << self
      def log_in(mail = nil, password = nil)
        Bookmeter.new.tap do |bookmeter|
          if block_given?
            config = Configuration.new
            yield config
            bookmeter.log_in(config.mail, config.password)
          else
            bookmeter.log_in(mail, password)
          end
        end
      end
    end


    def initialize(agent = nil)
      @agent          = agent.nil? ? Agent.new : agent
      @scraper        = Scraper.new(@agent)
      @logged_in      = false
      @log_in_user_id = nil
    end

    def log_in(mail = nil, password = nil)
      raise BookmeterError if @agent.nil?

      configuration = if block_given?
                        Configuration.new.tap { |config| yield config }
                      elsif mail.nil? && password.nil?
                        Configuration.new(DEFAULT_CONFIG_PATH)
                      else
                        Configuration.new.tap do |config|
                          config.mail     = mail
                          config.password = password
                        end
                      end

      @log_in_user_id = @agent.log_in(configuration)
      @logged_in      = !@log_in_user_id.nil?
    end

    def logged_in?
      @logged_in
    end

    def profile(user_id)
      @scraper.profile(user_id)
    end

    def read_books(user_id = @log_in_user_id)
      fetch_books(user_id, :read_books_uri)
    end

    def read_books_in(year, month, user_id = @log_in_user_id)
      date = Time.local(year, month)
      books = @scraper.get_read_books(user_id, date)
      books.each { |b| yield b } if block_given?
      books.to_a
    end

    def reading_books(user_id = @log_in_user_id)
      fetch_books(user_id, :reading_books_uri)
    end

    def tsundoku(user_id = @log_in_user_id)
      fetch_books(user_id, :tsundoku_uri)
    end

    def wish_list(user_id = @log_in_user_id)
      fetch_books(user_id, :wish_list_uri)
    end

    def followings(user_id = @log_in_user_id)
      @scraper.get_followings(user_id)
    end

    def followers(user_id = @log_in_user_id)
      @scraper.get_followers(user_id)
    end


    private

    def fetch_books(user_id, uri_method)
      books = @scraper.get_books(user_id, uri_method)
      books.each { |book| yield book } if block_given?
      books.to_a
    end
  end


  class BookmeterError < StandardError; end
end
