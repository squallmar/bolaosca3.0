# app/controllers/users/registrations_controller.rb
class Users::RegistrationsController < Devise::RegistrationsController
  after_action :log_flash_messages, only: [ :create ]

  private

  def log_flash_messages
    Rails.logger.info "Flash messages after registration: #{flash.inspect}"
  end
end
