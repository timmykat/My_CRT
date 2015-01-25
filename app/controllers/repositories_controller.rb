class RepositoriesController < ApplicationController
  before_filter :authenticate_superadmin!, :only => [:destroy]
  before_filter :authenticate_admin_or_staff!, :except => [:index, :show]

  def index
    @repositories = Repository.order('name')
  end

  def show
    @repository = Repository.find(params[:id])
    @courses = Course.where( repository_id: @repository.id ).order_by_last_date.limit(10).includes(:sections)
  end

  def new
    @repository = Repository.new
    @repository.attached_images.build
  end

  def edit
    @repository = Repository.find(params[:id])
  end

  def create
    remove_blank_image
    @repository = Repository.new(params[:repository])
    respond_to do |format|
      if @repository.save
        format.html { redirect_to repositories_url, notice: 'Library/Archive was successfully created.' }
        format.json { render json: @repository, status: :created, location: @repository }
      else
        format.html { render action: "new" }
        format.json { render json: @repository.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    remove_blank_image
    @repository = Repository.find(params[:id])
    respond_to do |format|
      if @repository.update_attributes(params[:repository])
        format.html { redirect_to repository_path(@repository), notice: 'Library/Archive was successfully updated.' }
        format.json { head :no_content }
      else
        format.html { render action: "edit" }
        format.json { render json: @repository.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @repository = Repository.find(params[:id])
    @repository.destroy

    respond_to do |format|
      format.html { redirect_to repositories_url }
      format.json { head :no_content }
    end
  end
  
  private
    def remove_blank_image
      last_image_field = params[:repository][:attached_images_attributes].keys.map{ |k| k.to_i }.max
      params[:repository][:attached_images_attributes].delete(last_image_field.to_s) if params[:repository][:attached_images_attributes][last_image_field.to_s]['image'].blank?    
    end  
end
