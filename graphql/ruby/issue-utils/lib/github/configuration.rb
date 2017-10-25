module GitHub
  class Configuration
    attr_reader :config_data

    CONFIG_ATTRIBUTES = %i{graphql_endpoint personal_access_token}.freeze

    def initialize(target:, config_path: "./config.yml")
      @config_data = YAML.load_file(config_path)[target.to_s]
    end

    CONFIG_ATTRIBUTES.each do |attr|
      define_method attr do
        config_data[attr.to_s]
      end
    end
  end
end
