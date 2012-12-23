class ProjectsController < ApplicationController

	before_filter :authenticate_user!, except: [:show, :index]
	before_filter :correct_user, only: [:edit, :update, :destroy]
	before_filter :get_sidebar_info, except: [:index, :show]

	def show
		@project = Project.find(params[:id])
		@page = @project.page
		@user = @page.user
		@user_projects = Project.find_all_by_page_id(@page.id)

		#get the tech tags for this project
		@tag_ids = Tagowner.find_all_by_project_id(params[:id])

		@tech_tags = Array.new
		@tag_ids.each do |f|
			#query for the rows associated with with these ids
			@tech_tags << TechTag.find(f.tech_tag_id)
		end
		#show edit blocks on hover if page_owner == 1
		@page_owner = is_page_owner?(@project.id)
		@comments = @project.comments.arrange(:order => :created_at)
		#get likes count for the right sidebar. 
		@likes_count = Like.count(:all, :conditions => ["project_id = ?", params[:id]])
	end

	def new_project 
	end

	def new
		@project = Project.new
	end

	def create
		@project = Project.new(params[:project])
		@project.page_id = Page.find_by_user_id(current_user.id).id

		tech_tag_tokens = params[:project][:tech_tag_tokens]
		if tech_tag_tokens
			@project.tag_list = turn_tag_ids_into_name_string(tech_tag_tokens)
		end

		if @project.save
			flash[:success] = "Your project has been created."
			redirect_to :controller => "pages", :action => "show", :id => current_user.username, only_path: true
		end
	end

	def edit
		@project = Project.find(params[:id])
		#going to have to differentiate all the editable fields below. Maybe get the value of the param. 
		#like edit_block = 'short_description'. try render :partial => '#{params[:edit_block]}'
		if params[:edit_block]
			if params[:edit_block] == "tech_tags"
				render "tech_tags"
			else 
				#render partial doesn't load the head css data, etc...
				render :partial => "#{params[:edit_block]}"
			end
		end
	end

	def update
		@project = Project.find(params[:id])
		
		#get the tags from the attributes and pass it into tag_list. 
		tech_tag_tokens = params[:project][:tech_tag_tokens]
		if tech_tag_tokens
			@project.tag_list = turn_tag_ids_into_name_string(tech_tag_tokens)
		end

		if @project.update_attributes(params[:project]) 
      flash[:success] = "Project updated"
      redirect_to :action => "edit", :id => params[:id], only_path: true
    else 
      render 'edit'
    end
	end

	def destroy
		#get the user page id
		@page_id = User.find(current_user.id).page.id
		project = Project.find(params[:id])
		if project.destroy
			flash[:success] = "Project Deleted"
      redirect_to :controller => "pages", :action => "edit", :id => @page_id, only_path: true
		else
			flash[:error] = "Something went wrong"
			redirect_to :controller => "pages", :action => "edit", :id => @page_id, only_path: true
		end
	end

	def project_type
		@project_type = params[:id]
		respond_to do |format|
			format.html 
      format.js { render :layout => false }
    end
	end

	def project_layout
		@project = Project.new
		@project_type = params[:project_type]
		@widget_type = params[:widget_type]
		respond_to do |format|
			format.html
      format.js { render :layout => false }
    end
	end

	def delete_picture
		r = Project.find(params[:id])
		r.remove_picture!
		r.remove_picture = true
		r.save
		respond_to do |format|
			format.html
      format.js { render :layout => false }
    end
	end

	private

		def get_user
    	@user = Project.find(params[:id]).page.user
    end    

    def count_subarrays array
		  return 0 unless array && array.is_a?(Array)

		  nested = array.select { |e| e.is_a?(Array) }
		  if nested.empty?
		    1 # this is a leaf
		  else
		    nested.inject(0) { |sum, ary| sum + count_subarrays(ary) }
		  end
		end

		def turn_tag_ids_into_name_string(tech_tag_tokens)
			#will be a csv string of tech_tag_ids. Need to get all of their names. 
			#turn them into array and then perform map on each value in array to turn into integer.
			tag_ids = tech_tag_tokens.split(",").map { |s| s.to_i }
			#now query Tagowner for the name and put into an array. Then join the array into a string with commas separating them. 
			tag_name_array = []
			tag_ids.each do |t|
				tag_name_array << TechTag.find(t).name
			end
			tag_list = tag_name_array.join(", ")
		end
end
