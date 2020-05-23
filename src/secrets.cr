require "aes"
require "yaml"
require "file_utils"

class SecretStore
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

  @@stores : Hash(String, SecretStore) = Hash(String, SecretStore).new
  class_property default_stores_dir : String = "./secrets"
  class_property default_keys_dir : String = "."

  def self.register(name : Symbol | String, store_path : String? = nil, key_path : String? = nil)
    name = name.to_s.downcase
    store_path ||= Path[default_stores_dir].join("#{name}_secrets.yml").to_s
    key_path ||= Path[default_keys_dir].join(".#{name}_secret_key").to_s
    stores_dir = Path[store_path].parent.to_s
    keys_dir = Path[key_path].parent.to_s
    FileUtils.mkdir_p(stores_dir)
    FileUtils.mkdir_p(keys_dir)
    if File.exists?(store_path)
      data = File.read(store_path)
      key = File.read(key_path)
      store = SecretStore.new(name, key, data)
    else
      store = SecretStore.new(name)
    end
    @@stores[name] = store
  end

  def self.[](name : Symbol | String)
    name = name.to_s.downcase
    @@stores[name]
  end

  def self.[]?(name : Symbol | String)
    name = name.to_s.downcase
    @@stores[name]?
  end
end
