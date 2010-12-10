class FeedbackMailer < ActionMailer::Base
  
  def feedback(feedback)
    @recipients  = 'zhangzd@opengoss.com'
    @from        = feedback.email
    @subject     = "[Feedback for Monit.cn] #{feedback.subject}"
    @sent_on     = Time.now
    @body[:feedback] = feedback    
  end

end
