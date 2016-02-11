require 'mechanize'

module BookmeterScraper
  class Bookmeter
    ROOT_URI  = 'http://bookmeter.com'.freeze
    LOGIN_URI = "#{ROOT_URI}/login".freeze

    PROFILE_ATTRIBUTES = %i(name gender age blood_type job address url description first_day elapsed_days read_books_count read_pages_count reviews_count bookshelfs_count)

    Profile = Struct.new(*PROFILE_ATTRIBUTES)

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

    def self.mypage_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}"
    end

    def self.read_books_uri(user_id)
      raise ArgumentError unless user_id =~ /^\d+$/
      "#{ROOT_URI}/u/#{user_id}/booklist"
    end

    def self.log_in(mail, password)
      agent = new_agent
      next_page = nil
      agent.get(LOGIN_URI) do |page|
        next_page = page.form_with(action: '/login') do |form|
          form.field_with(name: 'mail').value = mail
          form.field_with(name: 'password').value = password
        end.submit
      end

      bookmeter = Bookmeter.new(agent)
      bookmeter.instance_eval { @logged_in = next_page.uri.to_s == ROOT_URI + '/' }
      bookmeter
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


    private

    def self.new_agent
      agent = Mechanize.new do |a|
        a.user_agent_alias = 'Mac Safari'
      end
    end
  end

  class BookmeterError < StandardError; end
end
