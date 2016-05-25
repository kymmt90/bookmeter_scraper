module SpecMacros
  def set_up_logging_in(agent, scraper, bookmeter)
    configuration = BookmeterScraper::Configuration.new.tap do |c|
      c.mail, c.password = 'mail', 'password'
    end
    agent.log_in(configuration)
    scraper.agent = agent
    bookmeter.scraper = scraper
  end
end
