class ApplicationController < ActionController::Base
  # The dummy host's auth seam. Tests pick the acting user via a header; a real host
  # would resolve this from its session. Pinnable reads it through `config.current_user`.
  def current_user
    @current_user ||= User.find_by(id: session[:user_id] || request.headers["X-Test-User-Id"])
  end
end
