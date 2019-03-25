module Clerk
  class Role < Clerk::ApplicationRecord
    self.table_name = self.clerk_table_name("roles")
    self.primary_key = 'id'
  
    belongs_to :account, class_name: "Clerk::Account"

    # We need to migrate roles over to the new persistence strategy
    def self.clerk_persistence_path
      nil
    end
 
    def self.clerk_persistence_api
      nil
    end    

    def self._insert_record(values)
      begin 
        response = Clerk::ApplicationRecord.clerk_persistence_api.post('/roles', values)
        id = JSON.parse(response.body)["id"]
      rescue
        raise Clerk::Errors::ClerkServerError.new("Failed to save the role", self)
      end        

      if response.status != 200 or id.nil?
        raise Clerk::Errors::ClerkServerError.new("Failed to save the role", self)
      end
      
      return id
    end

    def self._update_record(values, constraints)
      update_id = constraints["id"]
      if update_id.nil?
        raise ActiveRecord::RecordNotFound.new("Must pass an id to update a role", self)
      end

      begin
        response = Clerk.api.patch("/roles/#{update_id}", values.merge!(constraints))
      rescue
        raise Clerk::Errors::ClerkServerError.new("Failed to update the role", self)
      end

      if response.status != 200
        raise Clerk::Errors::ClerkServerError.new("Failed to update the role", self)
      end

      # overriden function returns the number of rows affected
      return 1
    end

    def self._delete_record(constraints)
      delete_id = constraints["id"]
      if delete_id.nil?
        raise ActiveRecord::RecordNotFound.new("Must pass an id to delete a role", self)
      end

      begin
        response = Clerk.api.delete("/roles/#{delete_id}")
      rescue
        raise Clerk::Errors::ClerkServerError.new("Failed to delete the role", self)
      end


      if response.status != 200
        raise Clerk::Errors::ClerkServerError.new("Failed to delete the role", self)
      end

      # overriden function returns the number of rows affected
      return 1      
    end


    # disable bulk calls
    def self.update_all(updates)
      raise Clerk::Errors::MethodDisabled.new("update_all is disabled for Clerk::Role")
    end

    def self.delete_all
      raise Clerk::Errors::MethodDisabled.new("delete_all is disabled for Clerk::Role") 
    end    

    def self.destroy_all
      raise Clerk::Errors::MethodDisabled.new("destroy_all is disabled for Clerk::Role")
    end
  end
end

