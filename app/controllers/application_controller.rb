# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [ :full_name, :nickname, :phone, :avatar ])
    devise_parameter_sanitizer.permit(:account_update, keys: [ :full_name, :nickname, :phone, :avatar, :current_password ])
  end
end
