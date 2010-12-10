class IdeaComment < ActiveRecord::Base
  belongs_to :idea , :foreign_key=>"idea_id"
  belongs_to :user , :foreign_key=>"user_id"

  validates_presence_of :content
end
