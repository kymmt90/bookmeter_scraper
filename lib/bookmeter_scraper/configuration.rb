module BookmeterScraper
  class Configuration
    attr_accessor :mail, :password

    # Create a new configuration.
    # @param [String] config_file configuration file path
    # @return [BookmeterScraper::Configuration]
    def initialize(config_file = nil)
      if config_file.nil?
        @mail = @password = ''
        return
      end

      config = load_yaml_file(config_file)
      unless config.has_key?('mail') && config.has_key?('password')
        raise ConfigurationError, "#{config_file}: Invalid configuration file"
      end

      @mail     = config['mail']
      @password = config['password']
    end


    private

    def load_yaml_file(config_file)
      require 'yaml'
      YAML.load_file(config_file)
    end
  end

  class ConfigurationError < StandardError; end
end
