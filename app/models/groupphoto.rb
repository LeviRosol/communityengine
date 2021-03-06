class Groupphoto < ActiveRecord::Base
  acts_as_commentable
  
  has_attachment prepare_options_for_attachment_fu(AppConfig.groupphoto['attachment_fu_options'])

  acts_as_taggable

  #acts_as_activity :group, :if => Proc.new{|record| record.parent.nil?}

  #tracks_unlinked_activities [:created_a_groupphoto]

  validates_presence_of :size
  validates_presence_of :content_type
  validates_presence_of :filename
  validates_presence_of :group, :if => Proc.new{|record| record.parent.nil? }
  validates_inclusion_of :content_type, :in => attachment_options[:content_type], :message => "is not allowed", :allow_nil => true
  validates_inclusion_of :size, :in => attachment_options[:size], :message => " is too large", :allow_nil => true
  
  belongs_to :group
  has_one :group_as_avatar, :class_name => "Group", :foreign_key => "avatar_id"

  #attr_protected :group_id
  
  #Named scopes
  named_scope :recent, :order => "groupphotos.created_at DESC", :conditions => ["groupphotos.parent_id IS NULL"]
  named_scope :new_this_week, :order => "groupphotos.created_at DESC", :conditions => ["groupphotos.created_at > ? AND groupphotos.parent_id IS NULL", 7.days.ago.to_s(:db)]
  named_scope :tagged_with, lambda {|tag_name|
    {:conditions => ["tags.name = ?", tag_name], :include => :tags}
  }

  def display_name
    self.name ? self.name : self.created_at.strftime("created on: %m/%d/%y")
  end
  

  def description_for_rss
    "<a href='#{self.link_for_rss}' title='#{self.name}'><img src='#{self.public_filename(:large)}' alt='#{self.name}' /><br />#{self.description}</a>"
  end

  def owner
    self.group
  end

  def previous_groupphoto
    self.group.groupphotos.find(:first, :conditions => ['created_at < ?', created_at], :order => 'created_at DESC')
  end
  def next_groupphoto
    self.group.groupphotos.find(:first, :conditions => ['created_at > ?', created_at], :order => 'created_at ASC')
  end

  def self.find_recent(options = {:limit => 3})
    self.new_this_week.find(:all, :limit => options[:limit])
  end
  
  def self.find_related_to(groupphoto, options = {})
    merged_options = options.merge({:limit => 8, 
        :order => 'created_at DESC', 
        :conditions => ['groupphotos.id != ?', groupphoto.id]
    })
    groupphoto = find_tagged_with(groupphoto.tags.collect{|t| t.name }, merged_options).uniq
  end

end
