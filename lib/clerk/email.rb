module Clerk
  class Email < Clerk::ApplicationRecord
    self.table_name = self.clerk_table_name("emails")
    self.primary_key = 'id'
  end
end
