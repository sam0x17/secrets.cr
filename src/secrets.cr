require "aes"

module Secrets
  class SecretEnvironment
    getter name : String
    setter encryption_key : String
    getter data : Hash(String, String)

    def initialize(@name)
      @encryption_key = Random::Secure.hex(64)
      @data = Hash(String, String).new
    end

    def initialize(@name, @encryption_key, data : String)

    end

    def [](key : Symbol | String)
      key = key.to_s
      data[key]
    end

    def []?(key : Symbol | String)
      key = key.to_s
      data[key]?
    end
  end
end
