module Idv
  class PersonalKeyController < ApplicationController
    include IdvSession
    include SecureHeadersConcern

    before_action :apply_secure_headers_override
    before_action :confirm_two_factor_authenticated
    before_action :confirm_idv_vendor_session_started
    before_action :confirm_profile_has_been_created

    def show
      @step_indicator_steps = step_indicator_steps
      analytics.idv_personal_key_visited
      add_proofing_component

      finish_idv_session
    end

    def update
      user_session[:need_personal_key_confirmation] = false
      analytics.idv_personal_key_submitted
      redirect_to next_step
    end

    private

    def step_indicator_steps
      steps = Idv::Flows::DocAuthFlow::STEP_INDICATOR_STEPS
      return steps if idv_session.address_verification_mechanism != 'gpo'
      steps.map do |step|
        step[:name] == :verify_phone_or_address ? step.merge(status: :pending) : step
      end
    end

    def next_step
      if in_person_enrollment?
        idv_in_person_ready_to_verify_url
      elsif session[:sp] && !pending_profile?
        sign_up_completed_url
      elsif pending_profile? && idv_session.address_verification_mechanism == 'gpo'
        idv_come_back_later_url
      else
        after_sign_in_path_for(current_user)
      end
    end

    def confirm_profile_has_been_created
      redirect_to account_url if idv_session.profile.blank?
    end

    def add_proofing_component
      ProofingComponent.create_or_find_by(user: current_user).update(verified_at: Time.zone.now)
    end

    def finish_idv_session
      @code = personal_key
      user_session[:personal_key] = @code
      idv_session.personal_key = nil

      if idv_session.address_verification_mechanism == 'gpo'
        flash.now[:success] = t('idv.messages.mail_sent')
      else
        flash.now[:success] = t('idv.messages.confirm')
      end
      flash[:allow_confirmations_continue] = true
    end

    def personal_key
      idv_session.personal_key || generate_personal_key
    end

    def generate_personal_key
      cacher = Pii::Cacher.new(current_user, user_session)
      idv_session.profile.encrypt_recovery_pii(cacher.fetch)
    end

    def in_person_enrollment?
      # WILLFIX: After LG-6708 and we have enrollment saved, reference enrollment instead.
      ProofingComponent.find_by(user: current_user)&.document_check == Idp::Constants::Vendors::USPS
    end

    def pending_profile?
      current_user.pending_profile?
    end
  end
end
