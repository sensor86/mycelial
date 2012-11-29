class LikesController < ApplicationController
	before_filter :authenticate_user!

	def create
    @like = Like.create(params[:like])
    @project_id = params[:like][:project_id]
    #send a delayed job push notification to the user. Get the owner user_id from project_id
    @user_id = Project.find(@project_id).page.user.id
    Resque.enqueue(LikeNotifier, @user_id)
    render :toggle
  end

  def destroy
    like = Like.find(params[:id]).destroy
    @project_id = like.project_id
    render :toggle
  end
end
