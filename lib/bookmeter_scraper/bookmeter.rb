require 'bookmeter_scraper/agent'
require 'bookmeter_scraper/scraper'

module BookmeterScraper
  class Bookmeter
    DEFAULT_CONFIG_PATH = './config.yml'.freeze

    attr_reader :log_in_user_id
    attr_writer :scraper

    class << self
      # Log in Bookmeter.
      # If no arguments are passed, read those information from the configuration file.
      # @param [String] mail your Email address
      # @param [String] password your password
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

    # Log in Bookmeter.
    # If no arguments are passed, read those information from configuration file.
    # @param [String] mail your Email address
    # @param [String] password your password
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

    # Get a user profile.
    # @param user_id user ID
    # @return [BookmeterScraper::Profile] profile
    def profile(user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      @scraper.fetch_profile(user_id)
    end

    # Get a read books.
    # @param user_id user ID
    # @return [BookmeterScraper::Books] read books
    def read_books(user_id = @log_in_user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      fetch_books(user_id, :read_books_uri)
    end

    # Get books read in specified year-month.
    # @param year
    # @param month
    # @param user_id user ID
    # @return [BookmeterScraper::Books] read books
    def read_books_in(year, month, user_id = @log_in_user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX

      date = Time.local(year, month)
      books = @scraper.fetch_read_books_in(date, user_id)
      books.each { |b| yield b } if block_given?
      books.to_a
    end

    # Get reading books.
    # @param user_id User ID
    # @return [BookmeterScraper::Books] reading books
    def reading_books(user_id = @log_in_user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      fetch_books(user_id, :reading_books_uri)
    end

    # Get tsundoku (stockpiled books).
    # @param user_id User ID
    # @return [BookmeterScraper::Books] tsundoku (stockpiled books)
    def tsundoku(user_id = @log_in_user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      fetch_books(user_id, :tsundoku_uri)
    end

    # Get wish list.
    # @param user_id User ID
    # @return [BookmeterScraper::Books] books in wish list
    def wish_list(user_id = @log_in_user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      fetch_books(user_id, :wish_list_uri)
    end

    # Get following users.
    # @param user_id User ID
    # @return [Array] follwing users
    def followings(user_id = @log_in_user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      @scraper.fetch_followings(user_id)
    end

    # Get followers.
    # @param user_id User ID
    # @return [Array] followers
    def followers(user_id = @log_in_user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      @scraper.fetch_followers(user_id)
    end


    private

    def fetch_books(user_id, uri_method)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      raise ArgumentError unless BookmeterScraper.methods.include?(uri_method)

      books = @scraper.fetch_books(user_id, uri_method)
      books.each { |book| yield book } if block_given?
      books.to_a
    end
  end
end
