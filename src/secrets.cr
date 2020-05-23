require "aes"
require "yaml"

module Secrets
  class SecretEnvironment
    AES_BITS = 256
    KEY_SIZE = 32
    IV_SIZE = 32

    getter name : String
    setter encryption_key : String
    getter data : Hash(String, String)
    @aes : AES

    def initialize(@name)
      @data = Hash(String, String).new
      @aes = AES.new(AES_BITS)
      @encryption_key = String.new(@aes.@key)
    end

    def initialize(@name, @encryption_key, data : String)
      data = data.as_slice
      iv = data[0..(IV_SIZE - 1)]
      key = @encryption_key.as_slice
      data = data[IV_SIZE..]
      @aes = AES.new(key, iv, AES_BITS)
      decrypted = String.new(@aes.decrypt(data))
      yaml = YAML.parse(decrypted)
      @data = yaml.as_h.map { |k, v| [k.to_s, v.to_s] }.to_h
    end

    def encode
      mem = IO::Memory.new
      mem.write(@aes.iv)
      mem.write(@aes.encrypt(data.to_yaml))
      String.new(mem.to_slice)
    end

    def [](key : Symbol | String)
      data[key.to_s]
    end

    def []?(key : Symbol | String)
      data[key.to_s]?
    end

    def []=(key : Symbol | String, value : Symbol | String)
      data[key.to_s] = value.to_s
    end
  end
end
