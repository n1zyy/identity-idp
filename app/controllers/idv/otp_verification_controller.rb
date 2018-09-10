module Idv
  class OtpVerificationController < ApplicationController
    include IdvSession
    include PhoneOtpRateLimitable

    # confirm_two_factor_authenticated before action is in PhoneOtpRateLimitable
    before_action :confirm_step_needed
    before_action :confirm_otp_sent
    before_action :set_code
    before_action :set_otp_verification_presenter

    def show
      # memoize the form so the ivar is available to the view
      phone_confirmation_otp_verification_form
      analytics.track_event(Analytics::IDV_PHONE_CONFIRMATION_OTP_VISIT)
    end

    def update
      result = phone_confirmation_otp_verification_form.submit(code: params[:code])
      analytics.track_event(Analytics::IDV_PHONE_CONFIRMATION_OTP_SUBMITTED, result.to_h)
      if result.success?
        redirect_to idv_review_url
      else
        handle_otp_confirmation_failure
      end
    end

    private

    def confirm_step_needed
      return unless idv_session.user_phone_confirmation
      redirect_to idv_review_url
    end

    def confirm_otp_sent
      return if idv_session.phone_confirmation_otp.present? &&
                idv_session.phone_confirmation_otp_sent_at.present?

      redirect_to idv_otp_delivery_method_url
    end

    def set_code
      return unless FeatureManagement.prefill_otp_codes?
      @code = idv_session.phone_confirmation_otp
    end

    def set_otp_verification_presenter
      @presenter = OtpVerificationPresenter.new(idv_session: idv_session)
    end

    def handle_otp_confirmation_failure
      if decorated_user.locked_out?
        handle_too_many_otp_attempts
      else
        flash.now[:error] = t('devise.two_factor_authentication.invalid_otp')
        render :show
      end
    end

    def phone_confirmation_otp_verification_form
      @phone_confirmation_otp_verification_form ||= PhoneConfirmationOtpVerificationForm.new(
        user: current_user,
        idv_session: idv_session
      )
    end
  end
end
