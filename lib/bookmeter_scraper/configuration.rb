require 'yaml'

module BookmeterScraper
  class Configuration
    attr_reader :mail, :password

    def initialize(config_file)
      config = YAML.load_file(config_file)
      unless config.has_key?('mail') && config.has_key?('password')
        raise ConfigurationError, "#{config_file}: Invalid configuration file"
      end

      @mail     = config['mail']
      @password = config['password']
    end
  end

  class ConfigurationError < StandardError; end
end
