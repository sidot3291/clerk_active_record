module Clerk
  class SessionToken < Clerk::ApplicationRecord
    self.table_name = self.clerk_table_name("session_tokens")
    self.primary_key = 'id'

    belongs_to :account, class_name: "Clerk::Account"

    def self.find_account(cookie:)
      require "bcrypt"
      begin
        id, token, token_hash = decrypt(cookie).split("--")
        if BCrypt::Password.new(token_hash) == token
          Account.joins(:session_token).where(token_hash: token_hash, )
          SessionToken.eager_load(:account).find_by!(id: id, token_hash: token_hash)&.account
        else 
          nil
        end
      rescue => e
        puts "Error finding acount #{e}"
        puts "Cookie #{cookie}"
        nil
      end
    end

    private

      def self.cipher_key
        @@cipher_key ||= ::Base64.strict_decode64(ENV["CLERK_CIPHER_KEY"])
      end

      def self.decrypt(encrypted_message)
        cipher = OpenSSL::Cipher.new("aes-256-gcm")

        encrypted_data, iv, auth_tag = encrypted_message.split("--".freeze).map { |v| ::Base64.strict_decode64(v) }

        # Currently the OpenSSL bindings do not raise an error if auth_tag is
        # truncated, which would allow an attacker to easily forge it. See
        # https://github.com/ruby/openssl/issues/63
        raise InvalidMessage if (auth_tag.nil? || auth_tag.bytes.length != 16)

        cipher.decrypt
        cipher.key = cipher_key
        cipher.iv  = iv
        cipher.auth_tag = auth_tag
        cipher.auth_data = ""

        message = cipher.update(encrypted_data)
        message << cipher.final
        message
      end
  end
end
