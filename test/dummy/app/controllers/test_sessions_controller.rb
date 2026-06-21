# Stand-in host auth for tests: signs the browser session in as a given user so the
# system test drives a real authenticated session (not a header).
class TestSessionsController < ApplicationController
  def create
    session[:user_id] = params[:id]
    redirect_to params.fetch(:return_to, "/dashboard")
  end
end
