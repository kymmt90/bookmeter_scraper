require 'forwardable'

module BookmeterScraper
  class Agent
    extend Forwardable
    def_delegator :@agent, :get
    def_delegator :@agent, :click

    attr_reader :log_in_user_id


    def initialize
      @agent = Mechanize.new do |a|
        a.user_agent_alias = Mechanize::AGENT_ALIASES.keys.reject do |ua_alias|
          %w(Android iPad iPhone Mechanize).include?(ua_alias)
        end.sample
      end
      @log_in_user_id = nil
    end

    def log_in(config)
      raise ArgumentError if config.nil?

      page_after_submitting_form = nil
      @agent.get(BookmeterScraper::LOGIN_URI) do |page|
        page_after_submitting_form = page.form_with(action: '/login') do |form|
          form.field_with(name: 'session[email_address]').value     = config.mail
          form.field_with(name: 'session[password]').value = config.password
        end.submit
      end

      if page_after_logging_in? page_after_submitting_form
        mypage = page_after_submitting_form.link_with(text: 'マイページ').click
        @log_in_user_id = extract_user_id(mypage)
      else
        nil
      end
    end

    def logged_in?
      !@log_in_user_id.nil?
    end


    private

    def page_after_logging_in?(page)
      raise ArgumentError if page.nil?

      page.uri.to_s == BookmeterScraper::ROOT_URI + '/'
    end

    def extract_user_id(page)
      raise ArgumentError if page.nil?

      page.uri.to_s.match(/\/u\/(\d+)$/)[1]
    end
  end
end
