module Clerk
  class ApplicationRecord < ActiveRecord::Base
    self.abstract_class = true
    puts "Establish connection to #{ENV["CLERK_DATABASE_URL"]}"
    establish_connection ENV["CLERK_DATABASE_URL"]
    def self.clerk_table_name(table_name)
      "#{table_name}_01"
    end

    def self.clerk_persistence_path
      "/api/#{table_name[0...-3]}"
    end
 
    def self.clerk_persistence_api
      @@clerk_persistence_api ||= ClerkActiveRecord::Api::Connection.new(
        (ENV["CLERK_API_PATH"] || "https://api.clerk.dev"),
        ENV["CLERK_KEY"]&.slice(5..-1)
      )
    end

    def self.transaction(options = {}, &block)
      # were overriding all the methods that need transactions
      # these interfere with pgbouncer.  just yield the block
      yield
    rescue ActiveRecord::Rollback
      # rollbacks are silently swallowed
    end        
  end
end
