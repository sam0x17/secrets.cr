require "./spec_helper"

describe SecretStore do
  it "generates appropriate encryption key" do
    env = SecretStore.new("production")
    env.@encryption_key.size.should eq SecretStore::KEY_SIZE
    env.@aes.@key.size.should eq SecretStore::KEY_SIZE
  end

  it "completes encryption/decryption round trip" do
    env = SecretStore.new("development")
    env["API_KEY"] = "alskdjfas0dj90fjajsdf"
    env["SOME_KEY"] = "a8sd89fj8"
    orig_yaml = env.data.to_yaml
    encoded = env.encode
    encoded.should_not eq orig_yaml
    env = SecretStore.new("development", env.@encryption_key, encoded)
    env.data.to_yaml.should eq orig_yaml
  end

  it "saves and loads files" do
    SecretStore.register(:production)
    SecretStore[:production][:SOME_API_KEY] = "ja89dj98fjam89mdsioj"
    SecretStore[:production]["something else"] = "aj9sd8f8d"
    SecretStore[:production].save
    SecretStore.stores.clear
    SecretStore.register(:production)
    SecretStore[:production]["SOME_API_KEY"].should eq "ja89dj98fjam89mdsioj"
  end
end
