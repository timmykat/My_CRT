class CoursesController < ApplicationController
  before_filter :authenticate_admin_or_staff!, :only => [:take]
  before_filter :authenticate_user!, :except => [:take, :recent_show]
  
  def index
    @courses_all = Course.all(:order => "timeframe DESC, created_at DESC")
    @courses_mine_current = current_user.mine_current.paginate(:page => params[:mine_current_page], :per_page => 5)
    @courses_mine_past = current_user.mine_past.paginate(:page => params[:mine_past_page], :per_page => 5)
    @repositories = Repository.find(:all, :order => :name)
  end  
  
  def show
    @course = Course.find(params[:id])
    @note = Note.new
    @staff_only_notes = Note.find(:all, :conditions => {:course_id => @course.id, :staff_comment => true}, :order => "created_at DESC")
    @notes = Note.find(:all, :conditions => {:course_id => @course.id, :staff_comment => false}, :order => "created_at DESC")
  end
  
  def new
    unless params[:repository].nil? || params[:repository].blank?
      @course = Course.new(:repository_id => Repository.find(params[:repository]).id)
      @repository = Repository.find(params[:repository])
    else
      @course = Course.new  
    end  
    @uploader = FileUploader.new
  end
  
  def edit
    @course = Course.find(params[:id])
    @staff_involvement = @course.staff_involvement.split(',')
  end
  
  def create
    unless params[:course][:repository_id].nil? || params[:course][:repository_id].blank?
      @repository = Repository.find(params[:course][:repository_id])
      params[:course][:status] = "Unclaimed, Unscheduled" 
    else
      params[:course][:status] = "Homeless"
    end  
    
    if !params[:course][:timeframe].blank? && ((params[:course][:primary_contact_id].nil? && params[:course][:primary_contact_id].blank?) || (params[:course][:user_ids].nil? && params[:course][:user_ids][1].nil? && params[:course][:user_ids][1].empty?))
      params[:course][:status] = "Scheduled, Unclaimed"
    elsif !params[:course][:timeframe].blank? && ((!params[:course][:primary_contact_id].nil? && !params[:course][:primary_contact_id].blank?) || (!params[:course][:user_ids].nil? && !params[:course][:user_ids][1].nil? && !params[:course][:user_ids][1].empty?))
      params[:course][:status] = "Scheduled, Claimed" 
    elsif (params[:course][:timeframe].nil? || params[:course][:timeframe].blank?) && ((!params[:course][:primary_contact_id].nil? && !params[:course][:primary_contact_id].blank?) || (!params[:course][:user_ids].nil? && !params[:course][:user_ids][1].nil? && !params[:course][:user_ids][1].empty?))
      params[:course][:status] = "Claimed, Unscheduled"   
    end 
  
    params[:course][:timeframe] = DateTime.strptime(params[:course][:timeframe], '%m/%d/%Y %I:%M %P') unless params[:course][:timeframe].nil? || params[:course][:timeframe].empty?
    params[:course][:timeframe_2] = DateTime.strptime(params[:course][:timeframe_2], '%m/%d/%Y %I:%M %P') unless params[:course][:timeframe_2].nil? || params[:course][:timeframe_2].empty?
    params[:course][:timeframe_3] = DateTime.strptime(params[:course][:timeframe_3], '%m/%d/%Y %I:%M %P') unless params[:course][:timeframe_3].nil? || params[:course][:timeframe_3].empty?
    params[:course][:timeframe_4] = DateTime.strptime(params[:course][:timeframe_4], '%m/%d/%Y %I:%M %P') unless params[:course][:timeframe_4].nil? || params[:course][:timeframe_4].empty?
    params[:course][:pre_class_appt] = DateTime.strptime(params[:course][:pre_class_appt], '%m/%d/%Y %I:%M %P') unless params[:course][:pre_class_appt].nil? || params[:course][:pre_class_appt].empty?
    params[:course][:time_choice_1] = DateTime.strptime(params[:course][:time_choice_1], '%m/%d/%Y %I:%M %P') unless params[:course][:time_choice_1].empty?
    params[:course][:time_choice_2] = DateTime.strptime(params[:course][:time_choice_2], '%m/%d/%Y %I:%M %P') unless params[:course][:time_choice_2].empty?
    params[:course][:time_choice_3] = DateTime.strptime(params[:course][:time_choice_3], '%m/%d/%Y %I:%M %P') unless params[:course][:time_choice_3].empty?
    params[:course][:time_choice_4] = DateTime.strptime(params[:course][:time_choice_4], '%m/%d/%Y %I:%M %P') unless params[:course][:time_choice_4].empty?
    #params[:course][:pre_class_appt_choice_1] = DateTime.strptime(params[:course][:pre_class_appt_choice_1], '%m/%d/%Y %I:%M %P') unless params[:course][:pre_class_appt_choice_1].empty?
    #params[:course][:pre_class_appt_choice_2] = DateTime.strptime(params[:course][:pre_class_appt_choice_2], '%m/%d/%Y %I:%M %P') unless params[:course][:pre_class_appt_choice_2].empty?
    #params[:course][:pre_class_appt_choice_3] = DateTime.strptime(params[:course][:pre_class_appt_choice_3], '%m/%d/%Y %I:%M %P') unless params[:course][:pre_class_appt_choice_3].empty?
    
    @course = Course.new(params[:course])
    
    respond_to do |format|
      # if !@repository.nil? && !@course.number_of_students.nil?
      #   if @course.number_of_students > @repository.class_limit
      #     flash[:error] = "Please enter number of students below the repository maximum."
      #     format.html { render action: "new" }
      #     format.json { render json: @course.errors, status: :unprocessable_entity }
      #   end 
      # end   
        
      if @course.save
        @course.new_request_email
        if user_signed_in?
          format.html { redirect_to summary_course_url(@course), notice: 'Class was successfully created.' }
        else
          format.html { redirect_to summary_course_url(:id => @course.id), notice: 'Class was successfully submitted for approval.' }
        end    
      else
        flash[:error] = "Please correct the errors in the form."
        format.html { render action: "new" }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end  
    end
  end
  
  def update
    @course = Course.find(params[:id])
    
    unless params[:course][:repository_id].nil? || params[:course][:repository_id].blank?
      @repository = Repository.find(params[:course][:repository_id])
      params[:course][:status] = "Unclaimed, Unscheduled"
    else
      params[:course][:status] = "Homeless"
    end
    
    repo_change = false
    staff_change = false
    timeframe_change = false
    
    if (@course.repository.nil? || @course.repository.blank?) && (!params[:course][:repository_id].nil? && !params[:course][:repository_id].blank?)
      repo_change = true
    end
    if (@course.users.nil? || @course.users.blank?) && ((!params[:course][:primary_contact_id].nil? && !params[:course][:primary_contact_id].blank?) || (!params[:course][:user_ids].nil? && !params[:course][:user_ids][1].nil? && !params[:course][:user_ids][1].empty?))
      staff_change = true
    end
    if ((@course.timeframe.nil? || @course.timeframe.blank?) && (!params[:course][:timeframe].nil? && !params[:course][:timeframe].blank?)) || ((@course.timeframe_2.nil? || @course.timeframe_2.blank?) && (!params[:course][:timeframe_2].nil? && !params[:course][:timeframe_2].blank?)) || ((@course.timeframe_3.nil? || @course.timeframe_3.blank?) && (!params[:course][:timeframe_3].nil? && !params[:course][:timeframe_3].blank?)) || ((@course.timeframe_4.nil? || @course.timeframe_4.blank?) && (!params[:course][:timeframe_4].nil? && !params[:course][:timeframe_4].blank?))
      timeframe_change = true
    end
    
    if !params[:course][:timeframe].blank? && ((params[:course][:primary_contact_id].nil? && params[:course][:primary_contact_id].blank?) || (params[:course][:user_ids].nil? && params[:course][:user_ids][1].nil? && params[:course][:user_ids][1].empty?))
      params[:course][:status] = "Scheduled, Unclaimed"
    elsif !params[:course][:timeframe].blank? && ((!params[:course][:primary_contact_id].nil? && !params[:course][:primary_contact_id].blank?) || (!params[:course][:user_ids].nil? && !params[:course][:user_ids][1].nil? && !params[:course][:user_ids][1].empty?))
      params[:course][:status] = "Scheduled, Claimed" 
    elsif (params[:course][:timeframe].nil? || params[:course][:timeframe].blank?) && ((!params[:course][:primary_contact_id].nil? && !params[:course][:primary_contact_id].blank?) || (!params[:course][:user_ids].nil? && !params[:course][:user_ids][1].nil? && !params[:course][:user_ids][1].empty?))
      params[:course][:status] = "Claimed, Unscheduled"   
    end  
    
    params[:course][:timeframe] = DateTime.strptime(params[:course][:timeframe], '%m/%d/%Y %I:%M %P') unless params[:course][:timeframe].nil? || params[:course][:timeframe].empty?
    params[:course][:timeframe_2] = DateTime.strptime(params[:course][:timeframe_2], '%m/%d/%Y %I:%M %P') unless params[:course][:timeframe_2].nil? || params[:course][:timeframe_2].empty?
    params[:course][:timeframe_3] = DateTime.strptime(params[:course][:timeframe_3], '%m/%d/%Y %I:%M %P') unless params[:course][:timeframe_3].nil? || params[:course][:timeframe_3].empty?
    params[:course][:timeframe_4] = DateTime.strptime(params[:course][:timeframe_4], '%m/%d/%Y %I:%M %P') unless params[:course][:timeframe_4].nil? || params[:course][:timeframe_4].empty?
    params[:course][:pre_class_appt] = DateTime.strptime(params[:course][:pre_class_appt], '%m/%d/%Y %I:%M %P') unless params[:course][:pre_class_appt].nil? || params[:course][:pre_class_appt].empty?
    params[:course][:time_choice_1] = DateTime.strptime(params[:course][:time_choice_1], '%m/%d/%Y %I:%M %P') unless params[:course][:time_choice_1].empty?
    params[:course][:time_choice_2] = DateTime.strptime(params[:course][:time_choice_2], '%m/%d/%Y %I:%M %P') unless params[:course][:time_choice_2].empty?
    params[:course][:time_choice_3] = DateTime.strptime(params[:course][:time_choice_3], '%m/%d/%Y %I:%M %P') unless params[:course][:time_choice_3].empty?
    params[:course][:time_choice_4] = DateTime.strptime(params[:course][:time_choice_4], '%m/%d/%Y %I:%M %P') unless params[:course][:time_choice_4].empty?
    #params[:course][:pre_class_appt_choice_1] = DateTime.strptime(params[:course][:pre_class_appt_choice_1], '%m/%d/%Y %I:%M %P') unless params[:course][:pre_class_appt_choice_1].empty?
    #params[:course][:pre_class_appt_choice_2] = DateTime.strptime(params[:course][:pre_class_appt_choice_2], '%m/%d/%Y %I:%M %P') unless params[:course][:pre_class_appt_choice_2].empty?
    #params[:course][:pre_class_appt_choice_3] = DateTime.strptime(params[:course][:pre_class_appt_choice_3], '%m/%d/%Y %I:%M %P') unless params[:course][:pre_class_appt_choice_3].empty?
    
    # automatically close classes if date has approached
    # unless params[:course][:timeframe].nil? || params[:course][:timeframe].blank?
    #   if params[:course][:timeframe] < DateTime.now
    #     params[:course][:status] = "Closed"
    #   end 
    # end  
      
    respond_to do |format|
      if @course.update_attributes(params[:course])
        @course.updated_request_email 
        if params[:course][:status] == "Closed" && params[:send_email] == "1"
          @course.send_assessment_email
        end
        if repo_change == true
          @course.send_repo_change_email
        end
        if staff_change == true
          @course.send_staff_change_email  
        end
        if params[:send_timeframe_email] == "1"
          @course.send_timeframe_change_email  
        end
        
        format.html { redirect_to course_url(@course), notice: 'Class was successfully updated.' }
        format.json { head :no_content }
      else
        flash[:error] = "Please correct the errors in the form."
        format.html { render action: "edit" }
        format.json { render json: @course.errors, status: :unprocessable_entity }
      end
    end
  end
  
  def destroy
    @course = Course.find(params[:id])
    @course.destroy

    respond_to do |format|
      format.html { redirect_to courses_url }
      format.json { head :no_content }
    end
  end
  
  def summary
    @course = Course.find(params[:id])
  end
  
  def recent_show
    @course = Course.find(params[:id])
  end
  
  def repo_select
    unless params[:repo] == ""
      @repository = Repository.find(params[:repo])
    else
      @repository = ""
    end
    #render :partial => "shared/forms/course_staff_involvement"
    redirect_to new_course_path(:repository => @repository)
  end
  
  def take
    @course = Course.find(params[:id])
    @course.users << current_user
    if @course.repository.nil?
      @course.repository = current_user.repositories[0]
    end
    @course.save  
    respond_to do |format|
      format.html { redirect_to dashboard_welcome_index_url, notice: 'Class was successfully claimed.' }
    end  
  end
   
end
