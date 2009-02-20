class PrepItem < ActiveRecord::Base
  validates_presence_of :title, :description
  validates_uniqueness_of :title
  belongs_to :event_group
  belongs_to :project
  belongs_to :profile
  has_many :profile_prep_items, :include => :profile

  def self.find_prep_items
    find(:all, :order => "title")
  end
 
  def applies_to
    
    throw "PrepItems should exactly one of event_group_id, project_id or profile_id set" unless refs_set == 1
    
    if project
      :project
    elsif event_group
      :event_group
    else
      :profile
    end
  end
  
  def refs_set
    refs = 0
    refs += 1 if event_group
    refs += 1 if project
    refs += 1 if profile
    
    refs
  end
  
  def applies_to_profile(profile)
    return false unless profile.class == Acceptance
    (applies_to == :event_group && profile.project.event_group == event_group) || (applies_to == :project && project == profile.project)
  end
  
  def ensure_all_profile_prep_items_exist
    project_ids = if applies_to == :event_group then event_group.projects.collect(&:id) else [ project_id ] end
    projects = Project.find project_ids, :include => { :acceptances => :profile_prep_items }
    
    valid_acceptance_ids_with_ppi = []
    
    for project in projects
      for acceptance in project.acceptances
        #ppi = acceptance.profile_prep_items.find_or_create_by_prep_item_id self.id
        ppi = acceptance.profile_prep_items.detect { |ppi| ppi.prep_item_id == self.id }
        unless ppi
          ppi = acceptance.profile_prep_items.create! :prep_item_id => self.id
        end
        valid_acceptance_ids_with_ppi << acceptance.id
      end
    end
    
    # get rid of profile_prep_items for any profile that's switched projects
    if applies_to == :project
      for ppi in self.profile_prep_items
        unless ppi.profile && valid_acceptance_ids_with_ppi.include?(ppi.profile.id)
          ppi.destroy
        end
      end
    end
    
    return true
  end
end