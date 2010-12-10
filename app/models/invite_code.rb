class InviteCode < ActiveRecord::Base
  def generate
    self.code = User.make_token
    save
  end
end
