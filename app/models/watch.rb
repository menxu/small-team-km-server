class Watch < ActiveRecord::Base
  belongs_to :user
  belongs_to :data_list
end