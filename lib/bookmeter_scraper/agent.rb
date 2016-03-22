require 'bookmeter_scraper/bookmeter'

module BookmeterScraper
  class Agent
    extend Forwardable
    def_delegator :@agent, :get
    def_delegator :@agent, :click

    LOGIN_URI = "#{Bookmeter::ROOT_URI}/login".freeze

    def initialize
      @agent = Mechanize.new do |a|
        a.user_agent_alias = Mechanize::AGENT_ALIASES.keys.reject do |ua_alias|
          %w(Android iPad iPhone Mechanize).include?(ua_alias)
        end.sample
      end
    end

    def log_in(config)
      page_after_submitting_form = nil
      @agent.get(LOGIN_URI) do |page|
        page_after_submitting_form = page.form_with(action: '/login') do |form|
          form.field_with(name: 'mail').value     = config.mail
          form.field_with(name: 'password').value = config.password
        end.submit
      end

      if page_after_logging_in? page_after_submitting_form
        mypage = page_after_submitting_form.link_with(text: 'マイページ').click
        extract_user_id(mypage)
      else
        nil
      end
    end

    private

    def page_after_logging_in?(page)
      page.uri.to_s == Bookmeter::ROOT_URI + '/'
    end

    def extract_user_id(page)
      page.uri.to_s.match(/\/u\/(\d+)$/)[1]
    end
  end
end
