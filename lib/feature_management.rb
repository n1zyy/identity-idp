class FeatureManagement
  ENVS_WHERE_PREFILLING_USPS_CODE_ALLOWED = %w[
    idp.dev.login.gov idp.int.login.gov idp.qa.login.gov idp.pt.login.gov
    idp.dev.identitysandbox.gov idp.qa.identitysandbox.gov idp.int.identitysandbox.gov
    idp.pt.identitysandbox.gov
  ].freeze

  def self.telephony_test_adapter?
    Identity::Hostdata.settings.telephony_adapter.blank? ||
      Identity::Hostdata.settings.telephony_adapter == 'test'
  end

  def self.identity_pki_disabled?
    env = Identity::Hostdata.settings
    env.identity_pki_disabled == 'true' ||
      !env.piv_cac_service_url ||
      !env.piv_cac_verify_token_url
  end

  def self.development_and_identity_pki_disabled?
    # This controls if we try to hop over to identity-pki or just throw up
    # a screen asking for a Subject or one of a list of error conditions.
    Rails.env.development? && identity_pki_disabled?
  end

  def self.prefill_otp_codes?
    # In development, when SMS is disabled we pre-fill the correct codes so that
    # developers can log in without needing to configure SMS delivery.
    # We also allow this in production on a single server that is used for load testing.
    development_and_telephony_test_adapter? || prefill_otp_codes_allowed_in_sandbox?
  end

  def self.development_and_telephony_test_adapter?
    Rails.env.development? && telephony_test_adapter?
  end

  def self.prefill_otp_codes_allowed_in_sandbox?
    Identity::Hostdata.domain == 'identitysandbox.gov' && telephony_test_adapter?
  end

  def self.enable_load_testing_mode?
    Identity::Hostdata.settings.enable_load_testing_mode == 'true'
  end

  def self.use_kms?
    Identity::Hostdata.settings.use_kms == 'true'
  end

  def self.kms_multi_region_enabled?
    Identity::Hostdata.settings.aws_kms_multi_region_enabled == 'true'
  end

  def self.use_dashboard_service_providers?
    Identity::Hostdata.settings.use_dashboard_service_providers == 'true'
  end

  def self.enable_usps_verification?
    Identity::Hostdata.settings.enable_usps_verification == 'true'
  end

  def self.reveal_usps_code?
    Rails.env.development? || current_env_allowed_to_see_usps_code?
  end

  def self.current_env_allowed_to_see_usps_code?
    ENVS_WHERE_PREFILLING_USPS_CODE_ALLOWED.include?(Identity::Hostdata.settings.domain_name)
  end

  def self.show_demo_banner?
    Identity::Hostdata.in_datacenter? && Identity::Hostdata.env != 'prod'
  end

  def self.show_no_pii_banner?
    Identity::Hostdata.in_datacenter? && Identity::Hostdata.domain != 'login.gov'
  end

  def self.enable_saml_cert_rotation?
    Identity::Hostdata.settings.saml_secret_rotation_enabled == 'true'
  end

  def self.recaptcha_enabled?(session, reset)
    AbTest.new(:ab_test_recaptcha_enabled, Identity::Hostdata.settings.recaptcha_enabled_percent).
      enabled?(session, reset)
  end

  def self.disallow_all_web_crawlers?
    Identity::Hostdata.settings.disallow_all_web_crawlers == 'true'
  end

  def self.disallow_ial2_recovery?
    Identity::Hostdata.settings.disallow_ial2_recovery == 'true'
  end

  def self.backup_codes_as_only_2fa?
    Identity::Hostdata.settings.backup_codes_as_only_2fa == 'true'
  end

  def self.in_person_proofing_enabled?
    Identity::Hostdata.settings.in_person_proofing_enabled == 'true'
  end

  def self.usps_upload_enabled?
    Identity::Hostdata.settings.usps_upload_enabled == 'true'
  end

  def self.identity_pki_local_dev?
    # This option should only be used in the development environment
    # it controls if we hop over to identity-pki on a developers local machins
    Rails.env.development? && Identity::Hostdata.settings.identity_pki_local_dev == 'true'
  end

  def self.doc_capture_polling_enabled?
    Identity::Hostdata.settings.doc_capture_polling_enabled == 'true'
  end

  def self.document_capture_async_uploads_enabled?
    Identity::Hostdata.settings.doc_auth_enable_presigned_s3_urls == 'true'
  end

  def self.hide_phone_mfa_signup?
    Identity::Hostdata.settings.hide_phone_mfa_signup == 'true'
  end

  def self.liveness_checking_enabled?
    Identity::Hostdata.settings.liveness_checking_enabled == 'true'
  end

  def self.logo_upload_enabled?
    Identity::Hostdata.settings.logo_upload_enabled == 'true'
  end

  def self.log_to_stdout?
    !Rails.env.test? && Identity::Hostdata.settings.log_to_stdout == 'true'
  end

  # Whether or not we can call the phone_info endpoint at all
  def self.voip_check?
    Identity::Hostdata.settings.voip_check == 'true'
  end

  # Whether or not we should block VOIP phone numbers
  def self.voip_block?
    Identity::Hostdata.settings.voip_block == 'true'
  end

  # Manual allowlist for VOIPs, should only include known VOIPs that we use for smoke tests
  # @return [Set<String>] set of phone numbers normalized to e164
  def self.voip_allowed_phones
    @voip_allowed_phones ||= begin
      if (allowed_phones = Identity::Hostdata.settings.voip_allowed_phones).present?
        JSON.parse(allowed_phones).map { |p| Phonelib.parse(p).e164 }.to_set
      else
        Set.new
      end
    end
  end
end
