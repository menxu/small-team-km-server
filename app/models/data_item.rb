class DataItem < ActiveRecord::Base
  KIND_TEXT  = 'TEXT'
  KIND_IMAGE = 'IMAGE'
  KIND_URL   = 'URL'
  KIND_MUSIC = 'MUSIC'
  KINDS = [ KIND_TEXT, KIND_IMAGE, KIND_URL, KIND_MUSIC ]

  belongs_to :data_list
  belongs_to :file_entity
  belongs_to :music_info

  validates :title,        :presence => true,
    :uniqueness => {:scope => :data_list_id}
  validates :data_list_id, :presence => true
  validates :kind,         :presence => true, :inclusion => DataItem::KINDS

  validates :content,        :presence => {:if => lambda {|data_item| data_item.kind == DataItem::KIND_TEXT}}
  validates :file_entity,    :presence => {:if => lambda {|data_item| data_item.kind == DataItem::KIND_IMAGE}}
  validates :url,            :presence => {:if => lambda {|data_item| data_item.kind == DataItem::KIND_URL}},
    :uniqueness => {:scope => :data_list_id}

  validates :music_info,     :presence => {:if => lambda {|data_item| data_item.kind == DataItem::KIND_MUSIC}}

  after_save :set_data_list_delta_flag
  after_destroy :set_data_list_delta_flag
  def set_data_list_delta_flag
    data_list.delta = true
    data_list.save
  end

  after_save :set_data_list_updated_at
  after_destroy :set_data_list_updated_at
  def set_data_list_updated_at
    data_list.touch
  end

  before_create :set_position_value
  def set_position_value
    data_item = self.data_list.data_items.last
    if data_item.blank?
      self.position = SortChar.g(nil, nil)
    else
      self.position = SortChar.g(data_item.position, nil)
    end
  end

  # 列表项标题重复异常
  class TitleRepeatError < Exception; end;
  # 未知的 position 异常
  class UnKnownPositionError < Exception; end

  # 列表项URL重复异常
  class UrlRepeatError < Exception; end;

  def to_hash
    return {
      :id         => self.id,
      :title      => self.title,
      :kind       => self.kind,
      :position   => self.position,
      :content    => self.content,
      :url        => self.url,
      :seed       => self.seed,
      :image_url  => self.file_entity.blank? ? "" : self.file_entity.attach.url,

      :music_info => self.music_info.blank? ? {} : self.music_info.to_hash,


      :data_list => {
        :server_updated_time => self.data_list.updated_at.to_i
      }
    }
  end

  def update_by_params(param_title, param_value)
    attrs = {}
    attrs[:title] = param_title if !param_title.blank?

    case self.kind
    when DataItem::KIND_TEXT
      attrs[:content] = param_value if !param_value.blank?
    when DataItem::KIND_IMAGE
      attrs[:file_entity] = FileEntity.new(:attach => param_value) if !param_value.blank?
    when DataItem::KIND_URL
      attrs[:url] = param_value if !param_value.blank?
    end

    self.update_attributes(attrs)

    if !self.valid?
      raise DataItem::TitleRepeatError if self.errors.first[0] == :title && !self.title.blank?

      raise DataItem::UrlRepeatError if self.errors.first[0] == :url && !self.url.blank?
    end
  end

  def get_or_create_seed
    raise 'new_record is not support' if self.id.blank?

    if self.seed.blank?
      DataItem.where(:id=>self.id).update_all(:seed=>randstr)
      self.reload
    end

    self.seed
  end

  def insert_at(left_position, right_position)
    if !left_position.blank?
      data_item = self.data_list.data_items.find_by_position(left_position)
      raise DataItem::UnKnownPositionError.new if data_item.blank?
    end
    if !right_position.blank?
      data_item = self.data_list.data_items.find_by_position(right_position)
      raise DataItem::UnKnownPositionError.new if data_item.blank?
    end
    self.position = SortChar.g(left_position, right_position)
    self.save
  end
end
