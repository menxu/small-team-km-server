class Chat < ActiveRecord::Base
  has_many :chat_memberships
  has_many :chat_members, :through=>:chat_memberships, :source=>:user

  has_many :chat_nodes

  validates :uuid, :presence => true


  def to_hash
    members = self.chat_members.map do |user|
      {
        :user_id=>user.id,
        :user_name=>user.name,
        :user_avatar_url=>user.logo.url,
        :server_created_time=>user.created_at.to_i,
        :server_updated_time=>user.updated_at.to_i
      }
    end
    return {
      :uuid=>self.uuid,
      :server_chat_id=>self.id,
      :server_created_time=>self.created_at.to_i,
      :server_updated_time=>self.updated_at.to_i,
      :members=>members
    }
  end
end
