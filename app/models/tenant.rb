class Tenant < ActiveRecord::Base

  def self.authenticate_session(id, session_id)
    return (!id.blank? && !session_id.blank?) ? where({:id=> id, :session_id=> session_id}).first : nil
  end

end
