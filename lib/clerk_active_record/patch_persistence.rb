::ActiveRecord::Persistence.module_eval do 
  alias_method :_original_create_record, :_create_record

  def _clerk_create_record(attribute_names = self.attribute_names)
    # Send attributes on the database plus any custom attributes to the API
    attribute_names = attributes_for_create(attribute_names)
    attribute_names += (attributes.keys - self.class.columns_hash.keys)

    values = attributes_with_values(attribute_names)

    response = self.class.clerk_persistence_api.post(self.class.clerk_persistence_path, values)

    if response.status == 200
      new_id = JSON.parse(response.body)["id"]
    elsif response.status == 422
      response.data.each do |k, vs|
        vs.each do |v|
          self.errors.add(k, v)
        end
      end
      raise ActiveRecord::RecordInvalid.new(self)
    else
      Rails.logger.fatal "Server Failed: #{response.data[:message]}"
      raise ActiveRecord::RecordNotSaved.new("Failed to save the server record", self)
    end
    
    self.id ||= new_id if self.class.primary_key

    @new_record = false

    yield(self) if block_given?

    id
  end

  def _create_record(*args, &block)
    if defined?(self.class.clerk_persistence_path)
      _clerk_create_record(*args, &block)
    else
      _original_create_record(*args, &block)
    end
  end

  alias_method :_original_update_row, :_update_row

  def _clerk_update_row(attribute_names, attempted_action = "update")
    response = self.class.clerk_persistence_api.patch(
      "#{self.class.clerk_persistence_path}/#{id_in_database}", 
      attributes_with_values(attribute_names).except("updated_at")
    )

    if response.status == 200
      1 # Affected rows
    elsif response.status == 422
      response.data.each do |k, vs|
        vs.each do |v|
          self.errors.add(k, v)
        end
      end
      raise ActiveRecord::RecordInvalid.new(self)
    else
      Rails.logger.fatal "Server Failed: #{response.data[:message]}"
      raise ActiveRecord::RecordNotSaved.new("Failed to save the server record", self)
    end
  end

  def _update_row(*args, &block)
    if defined?(self.class.clerk_persistence_path)
      _clerk_update_row(*args, &block)
    else
      _original_update_row(*args, &block)
    end
  end
end