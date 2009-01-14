class MassEmailsController < ApplicationController
  skip_before_filter :get_notifications, :only => :emails
  before_filter :set_allowed_projects

  EMAIL_CHECK_OPTIONS = MyOrderedHash.new([
    "applying_started", { :class => "Applying", :txt => "Applying - Started", :status => 'started' }, 
    "applying_submitted", { :class => "Applying", :txt => "Applying - Submitted", :status => 'submitted' }, 
    "applying_completed", { :class => "Applying", :txt => "Applying - Completed", :status => 'completed' }, 
    "applying_unsubmitted", { :class => "Applying", :txt => "Applying - Unsubmitted", :status => 'unsubmitted' }, 
    "accepted", { :class => "Acceptance", :txt => "Accepted" }, 
    "staff", { :class => "StaffProfile", :txt => "Staff" }, 
    "withdrawn", { :class => "Withdrawn", :txt => "Withdrawn" }
  ])

  def index
    @submenu_title = "Mass Emails"
  end

  def emails
    # find by type then filter by status as required
    types = []
    projects = get_projects_for_emails
    classes = get_types_for_emails

    profiles = Profile.find_all_by_type_and_project_id(classes, projects.collect(&:id), 
                 :include => { :viewer => :persons }, 
                 :select => "#{Person.table_name}.person_email, #{Profile.table_name}.status, #{Profile.table_name}.type, #{Profile.table_name}.class_when_withdrawn"
               )

    # for applying, check the type
    if classes.include?('Applying')
      want_statuses = EMAIL_CHECK_OPTIONS.find_all{ |k,v| v[:class] == 'Applying' }.find_all{ |k,v|
                         params[k] == '1' }.collect{ |k,v| v[:status] }
      profiles.reject!{ |pr| pr.class == Applying && !want_statuses.include?(pr.status) }
    end

    # for withdrawn, remove all StaffProfiles unless Staff was checked as well
    if classes.include?('Withdrawn') && !classes.include?('StaffProfile')
      profiles.reject!{ |pr| pr.class == Withdrawn && pr.class_when_withdrawn == 'StaffProfile' }
    end

    emails = profiles.collect{ |pr| pr.viewer.person.email if pr.viewer && pr.viewer.person }.compact.uniq
    @result = if emails.empty? then '<I>Nothing found</I>' else emails.join(', ') end

    render :inline => @result
  end
  
  protected

  def set_allowed_projects
    @projects = if @user.is_projects_coordinator?
        @eg.projects
      else
        @user.viewer.current_projects_with_any_role(@eg)
      end
  end

  def get_projects_for_emails
    if params[:project_id] == 'any'
      @projects
    else
     [ @projects.detect{ |p| p.id.to_s == params[:project_id] } ]
    end
  end

  def get_types_for_emails
    types = []
    
    for id, o in EMAIL_CHECK_OPTIONS
      types << o[:class] if params[id] == '1'
    end

    types
  end
end