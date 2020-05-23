require "aes"
require "yaml"

class Secrets
  AES_BITS = 256
  KEY_SIZE = 32
  IV_SIZE = 32

  class_getter stores : Hash(String, Secrets) = Hash(String, Secrets).new
  class_property default_stores_dir : Path = Path["./secrets"]
  class_property default_keys_dir : Path = Path["."]

  getter name : String
  setter encryption_key : String
  getter data : Hash(String, String)
  property store_path : Path?
  property key_path : Path?
  @aes : AES

  alias SymString = Symbol | String
  alias PathString = Path | String

  def initialize(@name)
    @data = Hash(String, String).new
    @aes = AES.new(AES_BITS)
    @encryption_key = String.new(@aes.key)
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

  def [](key : SymString)
    data[key.to_s]
  end

  def []?(key : SymString)
    data[key.to_s]?
  end

  def []=(key : SymString, value : SymString)
    data[key.to_s] = value.to_s
  end

  def save
    File.write(store_path.not_nil!, encode)
    File.write(key_path.not_nil!, @encryption_key) unless File.exists?(key_path.not_nil!)
  end

  def self.register(name : SymString, store_path : PathString? = nil, key_path : PathString? = nil, create : Bool = false)
    name = name.to_s.downcase
    store_path ||= default_stores_dir.join("#{name}_secrets.enc.yml")
    key_path ||= default_keys_dir.join(".#{name}_secret_key")
    store_path = Path[store_path] if store_path.is_a?(String)
    key_path = Path[key_path] if key_path.is_a?(String)
    stores_dir = store_path.parent
    keys_dir = key_path.parent
    Dir.mkdir_p(stores_dir)
    Dir.mkdir_p(keys_dir)
    if File.exists?(store_path) && File.exists?(key_path)
      data = File.read(store_path)
      key = File.read(key_path)
      store = Secrets.new(name, key, data)
    elsif create
      store = Secrets.new(name)
    else
      return false
    end
    store.store_path = store_path
    store.key_path = key_path
    @@stores[name] = store
  end

  def self.[](name : SymString)
    name = name.to_s.downcase
    @@stores[name]
  end

  def self.[]?(name : SymString)
    name = name.to_s.downcase
    @@stores[name]?
  end
end
