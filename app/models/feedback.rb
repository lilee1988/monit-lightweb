class Feedback
  attr_accessor :subject, :email, :comment, :referer
  
  def initialize(params = {})
    self.referer = params[:referer]
    self.subject = params[:subject]
    self.email = params[:email]
    self.comment = params[:comment]
  end
  
  def valid?
    self.comment && !self.comment.strip.blank?
  end

end
