module VCAP::CloudController
  class SecurityGroupDeleteAction
    def delete(security_groups)
      security_groups.each do |security_group|
        SecurityGroup.db.transaction do
          security_group.destroy
        end
      end
      []
    end
  end
end
