class Idea < ActiveRecord::Base
  has_many :comments, :class_name => "IdeaComment"
  has_many :idea_votes
  belongs_to :idea_type, :foreign_key=>"type_id"
  belongs_to :user, :foreign_key=>"user_id"

  validates_presence_of :title
  validates_presence_of :content

  def self.find_categories(typeid,page,order)
    query_conn={}
    query_conn[:from]="ideas t1 left join idea_votes t2 on t1.id=t2.idea_id"
    query_conn[:select]="t1.* ,sum(t2.num) num"
    query_conn[:group]="t1.id"
    if order=="recent"
        query_conn[:order]="t1.updated_at desc"
    elsif order=="top"
        query_conn[:order]="num desc"
    end
    if typeid.to_i==0
      paginate query_conn.merge(:page => page, :per_page =>30)
    else
      query_conn[:conditions]="t1.type_id=#{typeid}"
      paginate query_conn.merge(:page => page, :per_page =>30)
    end
  end

  def self.find_idea(id)
    find_by_sql("select t1.*,sum(t2.num) num from ideas t1  left join idea_votes t2 on t1.id=t2.idea_id where t1.id=#{id} group by t1.id")
  end
end
