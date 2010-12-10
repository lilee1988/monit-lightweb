class IdeaVote < ActiveRecord::Base

  belongs_to :idea , :foreign_key=>"idea_id"
  belongs_to :user , :foreign_key=>"user_id"

  validates_uniqueness_of :idea_id, :scope=>[:user_id],:message=>"您已投过一次票了！"


  def  self.save_vote(idea_id,user_id,num)
    ideavote=IdeaVote.new
    ideavote.idea_id=idea_id
    ideavote.user_id=user_id
    ideavote.num=num
    ideavote.save
  end

end
