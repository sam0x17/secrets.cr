require "aes"
require "yaml"

class SecretStore
  AES_BITS = 256
  KEY_SIZE = 32
  IV_SIZE = 32

  class_getter stores : Hash(String, SecretStore) = Hash(String, SecretStore).new
  class_property default_stores_dir : Path = Path["./secrets"]
  class_property default_keys_dir : Path = Path["."]

  getter name : String
  setter encryption_key : String
  getter data : Hash(String, String)
  property store_path : Path?
  property key_path : Path?
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

  def save
    File.write(store_path.not_nil!, encode)
    File.write(key_path.not_nil!, @encryption_key) unless File.exists?(key_path.not_nil!)
  end

  def self.register(name : Symbol | String, store_path : String | Path | Nil = nil, key_path : String | Path | Nil = nil)
    name = name.to_s.downcase
    store_path ||= default_stores_dir.join("#{name}_secrets.yml")
    key_path ||= default_keys_dir.join(".#{name}_secret_key")
    store_path = Path[store_path] if store_path.is_a?(String)
    key_path = Path[key_path] if key_path.is_a?(String)
    stores_dir = store_path.parent
    keys_dir = key_path.parent
    Dir.mkdir_p(stores_dir)
    Dir.mkdir_p(keys_dir)
    if File.exists?(store_path)
      data = File.read(store_path)
      key = File.read(key_path)
      store = SecretStore.new(name, key, data)
    else
      store = SecretStore.new(name)
    end
    store.store_path = store_path
    store.key_path = key_path
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
