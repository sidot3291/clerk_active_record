module Clerk
  class Account < Clerk::ApplicationRecord
    self.table_name = self.clerk_table_name("accounts")
    self.primary_key = 'id'

    has_many :roles, class_name: "Clerk::Role"
    has_many :emails, class_name: "Clerk::Email"

    def email(
      from_email_name:,
      email_template_token: nil,
      replacements: nil,
      subject: nil,
      body: nil
    )
      Clerk::Email.create(
        account_id: self.id,
        from_email_name: from_email_name,
        email_template_token: email_template_token,
        replacements: replacements,
        subject: subject,
        body: body
      )
    end


    def add_clerk_role(role_type_symbol, instance = nil)
      json = { }
      json[:name] = role_type_symbol.to_s
      json[:account_id] = self.id

      if not instance.nil?
        json[:scope_class] = instance.class.name
        json[:scope_id] = instance.id
      end

      server_url = "#{Clerk.accounts_url}/roles"
      HTTP.auth("Bearer #{Clerk.key}").post(server_url, :json => json)
    end

    def has_role?(role, scope)
      roles.where(name: role, scope_class: scope.class.name, scope_id: scope.id).exists?
    end

    def roles_for(scope)
      roles.where(scope_class: scope.class.name, scope_id: scope.id).pluck(:name).map(&:to_sym)
    end

    def has_permission?(permission, scope)
      has_role?(scope.class.roles_with_permission(permission), scope)
    end

    def permissions_for(scope)
      permissions = Set.new

      roles = roles_for(scope)
      roles.each do |role|
        role_permissions = scope.class.clerk_permissions_map[role]

        unless role_permissions.nil?
          permissions.merge(role_permissions)
        end
      end

      return permissions.to_a
    end

    private

      def method_missing(method_name, *args, &block)
        # Rails lazy loads modules.  If an object hasn't been loaded yet, any inverse association
        # will not be here yet.  Just in case, load the constant here and re-call the method to
        # before raising an error
        @miss_test ||= {}
        if @miss_test.has_key? method_name.to_sym
          super
        else
          @miss_test[method_name.to_sym] = true
          scope_class = method_name.to_s.classify.constantize
          send(method_name, *args, &block)  
        end
      rescue => e
        super
      end

      class RolesWrapper
        def initialize(instance, target)
          @instance = instance
          @target_class = target.to_s.classify.constantize
        end

        def with(role: nil, permission: nil)
          if (role.nil? and permission.nil?) or (not role.nil? and not permission.nil?)
            raise ArgumentError.new("Invalid argument, must supply either a role or permission")
          end

          if not role.nil?
            return @target_class.where( 
              id: @instance.roles.where(scope_class: @target_class.name, name: role).pluck(:scope_id) 
            )
          end

          if not permission.nil?
            roles = @target_class.roles_with_permission(permission)
            return @target_class.where(
              id: @instance.roles.where(scope_class: @target_class.name, name: roles).pluck(:scope_id)
            )            
          end
        end

        def no_with
          @target_class.where( 
            id: @instance.roles.where(scope_class: @target_class.name).pluck(:scope_id) 
          )
        end

        def method_missing(m, *args, &block)
          no_with.send(m, *args, &block)
        end

        def inspect
          no_with.inspect
        end
      end
  end
end