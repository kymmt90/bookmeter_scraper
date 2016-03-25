require 'bookmeter_scraper/bookmeter'
require 'bookmeter_scraper/configuration'
require 'bookmeter_scraper/version'

module BookmeterScraper
  ROOT_URI  = 'http://bookmeter.com'.freeze
  LOGIN_URI = "#{ROOT_URI}/login".freeze

  USER_ID_REGEX = /^\d+$/

  class << self
    def mypage_uri(user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      "#{ROOT_URI}/u/#{user_id}"
    end

    def read_books_uri(user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      "#{ROOT_URI}/u/#{user_id}/booklist"
    end

    def reading_books_uri(user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      "#{ROOT_URI}/u/#{user_id}/booklistnow"
    end

    def tsundoku_uri(user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      "#{ROOT_URI}/u/#{user_id}/booklisttun"
    end

    def wish_list_uri(user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      "#{ROOT_URI}/u/#{user_id}/booklistpre"
    end

    def followings_uri(user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      "#{ROOT_URI}/u/#{user_id}/favorite_user"
    end

    def followers_uri(user_id)
      raise ArgumentError unless user_id =~ USER_ID_REGEX
      "#{ROOT_URI}/u/#{user_id}/favorited_user"
    end
  end

  class BookmeterError < StandardError; end
end
