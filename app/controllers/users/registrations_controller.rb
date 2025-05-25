# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  before_action :configure_permitted_parameters
  after_action :log_flash_messages, only: [:create]

  protected

  def configure_permitted_parameters
    # Permite parâmetros adicionais para sign up e account update
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :avatar])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :avatar])
  end

  # Sobrescreva o método update_resource para lidar com a senha corretamente
  def update_resource(resource, params)
    if params[:password].blank? && params[:password_confirmation].blank?
      resource.update_without_password(params.except(:current_password))
    else
      super
    end
  end

  private

  def log_flash_messages
    Rails.logger.info "Flash messages after registration: #{flash.inspect}"
  end
end