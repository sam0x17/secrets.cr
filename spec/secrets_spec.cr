require "./spec_helper"

module Secrets
  describe SecretStore do
    it "generates appropriate encryption key" do
      env = SecretStore.new("production")
      env.@encryption_key.size.should eq SecretStore::KEY_SIZE
      env.@aes.@key.size.should eq SecretStore::KEY_SIZE
    end

    it "encryption/decryption round trip" do
      env = SecretStore.new("development")
      env["API_KEY"] = "alskdjfas0dj90fjajsdf"
      env["SOME_KEY"] = "a8sd89fj8"
      orig_yaml = env.data.to_yaml
      encoded = env.encode
      encoded.should_not eq orig_yaml
      env = SecretStore.new("development", env.@encryption_key, encoded)
      env.data.to_yaml.should eq orig_yaml
    end
  end
end
