require "./spec_helper"

describe Secrets do
  it "generates appropriate encryption key" do
    env = Secrets.new("production")
    env.@encryption_key.size.should eq Secrets::KEY_SIZE
    env.@aes.@key.size.should eq Secrets::KEY_SIZE
  end

  it "completes encryption/decryption round trip" do
    env = Secrets.new("development")
    env["API_KEY"] = "alskdjfas0dj90fjajsdf"
    env["SOME_KEY"] = "a8sd89fj8"
    orig_yaml = env.data.to_yaml
    encoded = env.encode
    encoded.should_not eq orig_yaml
    env = Secrets.new("development", env.@encryption_key, encoded)
    env.data.to_yaml.should eq orig_yaml
  end

  it "saves and loads files" do
    Secrets.register(:production)
    Secrets[:production][:SOME_API_KEY] = "ja89dj98fjam89mdsioj"
    Secrets[:production]["something else"] = "aj9sd8f8d"
    Secrets[:production].save
    Secrets.stores.clear
    Secrets.register(:production)
    Secrets[:production]["SOME_API_KEY"].should eq "ja89dj98fjam89mdsioj"
  end
end
