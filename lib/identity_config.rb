class IdentityConfig
  GIT_SHA = `git rev-parse --short=8 HEAD`.chomp
  GIT_TAG = `git tag --points-at HEAD`.chomp.split("\n").first
  GIT_BRANCH = `git rev-parse --abbrev-ref HEAD`.chomp

  VENDOR_STATUS_OPTIONS = %i[operational partial_outage full_outage]

  class << self
    attr_reader :store
  end

  CONVERTERS = {
    string: proc { |value| value.to_s },
    symbol: proc { |value| value.to_sym },
    comma_separated_string_list: proc do |value|
      value.split(',')
    end,
    integer: proc do |value|
      Integer(value)
    end,
    float: proc do |value|
      Float(value)
    end,
    json: proc do |value, options: {}|
      JSON.parse(value, symbolize_names: options[:symbolize_names])
    end,
    boolean: proc do |value|
      case value
      when 'true', true
        true
      when 'false', false
        false
      else
        raise 'invalid boolean value'
      end
    end,
    date: proc { |value| Date.parse(value) if value },
    timestamp: proc do |value|
      # When the store is built `Time.zone` is not set resulting in a NoMethodError
      # if Time.zone.parse is called
      #
      # rubocop:disable Rails/TimeZone
      Time.parse(value)
      # rubocop:enable Rails/TimeZone
    end,
  }

  def initialize(read_env)
    @read_env = read_env
    @written_env = {}
  end

  def add(key, type: :string, allow_nil: false, enum: nil, options: {})
    value = @read_env[key]

    converted_value = CONVERTERS.fetch(type).call(value, options: options) if !value.nil?
    raise "#{key} is required but is not present" if converted_value.nil? && !allow_nil
    if enum && !enum.include?(converted_value)
      raise "unexpected #{key}: #{value}, expected one of #{enum}"
    end

    @written_env[key] = converted_value
    @written_env
  end

  attr_reader :written_env

  def self.build_store(config_map)
    config = IdentityConfig.new(config_map)
    config.add(:aamva_auth_request_timeout, type: :float)
    config.add(:aamva_auth_url, type: :string)
    config.add(:aamva_cert_enabled, type: :boolean)
    config.add(:aamva_private_key, type: :string)
    config.add(:aamva_public_key, type: :string)
    config.add(:aamva_sp_banlist_issuers, type: :json)
    config.add(:aamva_supported_jurisdictions, type: :json)
    config.add(:aamva_verification_request_timeout, type: :float)
    config.add(:aamva_verification_url)
    config.add(:all_redirect_uris_cache_duration_minutes, type: :integer)
    config.add(:account_reset_token_valid_for_days, type: :integer)
    config.add(:account_reset_wait_period_days, type: :integer)
    config.add(:acuant_maintenance_window_start, type: :timestamp, allow_nil: true)
    config.add(:acuant_maintenance_window_finish, type: :timestamp, allow_nil: true)
    config.add(:acuant_assure_id_password)
    config.add(:acuant_assure_id_username)
    config.add(:acuant_assure_id_subscription_id)
    config.add(:acuant_assure_id_url)
    config.add(:acuant_facial_match_url)
    config.add(:acuant_passlive_url)
    config.add(:acuant_sdk_initialization_creds)
    config.add(:acuant_sdk_initialization_endpoint)
    config.add(:acuant_timeout, type: :float)
    config.add(:acuant_upload_image_timeout, type: :float)
    config.add(:acuant_get_results_timeout, type: :float)
    config.add(:acuant_create_document_timeout, type: :float)
    config.add(:add_email_link_valid_for_hours, type: :integer)
    config.add(:asset_host, type: :string)
    config.add(:async_wait_timeout_seconds, type: :integer)
    config.add(:async_stale_job_timeout_seconds, type: :integer)
    config.add(:attribute_encryption_key, type: :string)
    config.add(:attribute_encryption_key_queue, type: :json)
    config.add(:aws_http_retry_limit, type: :integer)
    config.add(:aws_http_retry_max_delay, type: :integer)
    config.add(:aws_http_timeout, type: :integer)
    config.add(:aws_kms_key_id, type: :string)
    config.add(:aws_kms_multi_region_enabled, type: :boolean)
    config.add(:aws_kms_regions, type: :json)
    config.add(:aws_logo_bucket, type: :string)
    config.add(:aws_region, type: :string)
    config.add(:backup_code_cost, type: :string)
    config.add(:broken_personal_key_window_start, type: :timestamp)
    config.add(:broken_personal_key_window_finish, type: :timestamp)
    config.add(:country_phone_number_overrides, type: :json)
    config.add(:dashboard_api_token, type: :string)
    config.add(:dashboard_url, type: :string)
    config.add(:database_host, type: :string)
    config.add(:database_name, type: :string)
    config.add(:database_readonly_password, type: :string)
    config.add(:database_readonly_username, type: :string)
    config.add(:database_read_replica_host, type: :string)
    config.add(:database_password, type: :string)
    config.add(:database_pool_idp, type: :integer)
    config.add(:database_statement_timeout, type: :integer)
    config.add(:database_timeout, type: :integer)
    config.add(:database_username, type: :string)
    config.add(:database_worker_jobs_name, type: :string)
    config.add(:database_worker_jobs_username, type: :string)
    config.add(:database_worker_jobs_host, type: :string)
    config.add(:database_worker_jobs_password, type: :string)
    config.add(:deleted_user_accounts_report_configs, type: :json)
    config.add(:deliver_mail_async, type: :boolean)
    config.add(:disable_csp_unsafe_inline, type: :boolean)
    config.add(:disable_email_sending, type: :boolean)
    config.add(:disallow_all_web_crawlers, type: :boolean)
    config.add(:disposable_email_services, type: :json)
    config.add(:doc_auth_attempt_window_in_minutes, type: :integer)
    config.add(:doc_auth_client_glare_threshold, type: :integer)
    config.add(:doc_auth_client_sharpness_threshold, type: :integer)
    config.add(:doc_auth_enable_presigned_s3_urls, type: :boolean)
    config.add(:doc_auth_error_dpi_threshold, type: :integer)
    config.add(:doc_auth_error_glare_threshold, type: :integer)
    config.add(:doc_auth_error_sharpness_threshold, type: :integer)
    config.add(:doc_auth_extend_timeout_by_minutes, type: :integer)
    config.add(:doc_auth_max_attempts, type: :integer)
    config.add(:doc_auth_max_capture_attempts_before_tips, type: :integer)
    config.add(:doc_auth_s3_request_timeout, type: :integer)
    config.add(:doc_auth_vendor, type: :string)
    config.add(:doc_auth_vendor_randomize, type: :boolean)
    config.add(:doc_auth_vendor_randomize_percent, type: :integer)
    config.add(:doc_auth_vendor_randomize_alternate_vendor, type: :string)
    config.add(:doc_capture_polling_enabled, type: :boolean)
    config.add(:doc_capture_request_valid_for_minutes, type: :integer)
    config.add(:domain_name, type: :string)
    config.add(:email_from, type: :string)
    config.add(:email_from_display_name, type: :string)
    config.add(:enable_load_testing_mode, type: :boolean)
    config.add(:enable_numeric_authentication_otp, type: :boolean)
    config.add(:enable_partner_api, type: :boolean)
    config.add(:enable_rate_limiting, type: :boolean)
    config.add(:enable_test_routes, type: :boolean)
    config.add(:enable_usps_verification, type: :boolean)
    config.add(:event_disavowal_expiration_hours, type: :integer)
    config.add(:geo_data_file_path, type: :string)
    config.add(:good_job_max_threads, type: :integer)
    config.add(:good_job_queues, type: :string)
    config.add(:gpo_designated_receiver_pii, type: :json, options: { symbolize_names: true })
    config.add(:hide_phone_mfa_signup, type: :boolean)
    config.add(:hmac_fingerprinter_key, type: :string)
    config.add(:hmac_fingerprinter_key_queue, type: :json)
    config.add(:identity_pki_disabled, type: :boolean)
    config.add(:identity_pki_local_dev, type: :boolean)
    config.add(:idv_api_enabled_steps, type: :json, options: { symbolize_names: true })
    config.add(:idv_attempt_window_in_hours, type: :integer)
    config.add(:idv_max_attempts, type: :integer)
    config.add(:idv_min_age_years, type: :integer)
    config.add(:idv_private_key, type: :string)
    config.add(:idv_public_key, type: :string)
    config.add(:idv_send_link_attempt_window_in_minutes, type: :integer)
    config.add(:idv_send_link_max_attempts, type: :integer)
    config.add(:idv_sp_required, type: :boolean)
    config.add(:in_person_proofing_enabled, type: :boolean)
    config.add(:in_person_proofing_enabled_issuers, type: :json)
    config.add(:include_slo_in_saml_metadata, type: :boolean)
    config.add(:irs_attempt_api_audience)
    config.add(:irs_attempt_api_auth_tokens, type: :comma_separated_string_list)
    config.add(:irs_attempt_api_enabled, type: :boolean)
    config.add(:irs_attempt_api_event_ttl_seconds, type: :integer)
    config.add(:irs_attempt_api_event_count_default, type: :integer)
    config.add(:irs_attempt_api_event_count_max, type: :integer)
    config.add(:irs_attempt_api_public_key)
    config.add(:kantara_2fa_phone_restricted, type: :boolean)
    config.add(:kantara_2fa_phone_existing_user_restriction, type: :boolean)
    config.add(:kantara_restriction_enforcement_date, type: :timestamp)
    config.add(:lexisnexis_base_url, type: :string)
    config.add(:lexisnexis_request_mode, type: :string)
    config.add(:lexisnexis_account_id, type: :string)
    config.add(:lexisnexis_username, type: :string)
    config.add(:lexisnexis_password, type: :string)
    config.add(:lexisnexis_phone_finder_timeout, type: :float)
    config.add(:lexisnexis_phone_finder_workflow, type: :string)
    config.add(:lexisnexis_instant_verify_timeout, type: :float)
    config.add(:lexisnexis_instant_verify_workflow, type: :string)
    config.add(:lexisnexis_trueid_account_id, type: :string)
    config.add(:lexisnexis_trueid_username, type: :string)
    config.add(:lexisnexis_trueid_password, type: :string)
    config.add(:lexisnexis_trueid_liveness_cropping_workflow, type: :string)
    config.add(:lexisnexis_trueid_liveness_nocropping_workflow, type: :string)
    config.add(:lexisnexis_trueid_noliveness_cropping_workflow, type: :string)
    config.add(:lexisnexis_trueid_noliveness_nocropping_workflow, type: :string)
    config.add(:lexisnexis_trueid_timeout, type: :float)
    config.add(:liveness_checking_enabled, type: :boolean)
    config.add(:lockout_period_in_minutes, type: :integer)
    config.add(:log_to_stdout, type: :boolean)
    config.add(:logins_per_email_and_ip_bantime, type: :integer)
    config.add(:logins_per_email_and_ip_limit, type: :integer)
    config.add(:logins_per_email_and_ip_period, type: :integer)
    config.add(:logins_per_ip_limit, type: :integer)
    config.add(:logins_per_ip_period, type: :integer)
    config.add(:logins_per_ip_track_only_mode, type: :boolean)
    config.add(:logo_upload_enabled, type: :boolean)
    config.add(:newrelic_browser_app_id, type: :string)
    config.add(:newrelic_browser_key, type: :string)
    config.add(:newrelic_license_key, type: :string)
    config.add(:new_sign_up_cancellation_url_enabled, type: :boolean)
    config.add(:mailer_domain_name)
    config.add(:max_auth_apps_per_account, type: :integer)
    config.add(:max_bad_passwords, type: :integer)
    config.add(:max_bad_passwords_window_in_seconds, type: :integer)
    config.add(:max_emails_per_account, type: :integer)
    config.add(:max_mail_events, type: :integer)
    config.add(:max_mail_events_window_in_days, type: :integer)
    config.add(:max_phone_numbers_per_account, type: :integer)
    config.add(:max_piv_cac_per_account, type: :integer)
    config.add(:min_password_score, type: :integer)
    config.add(:mx_timeout, type: :integer)
    config.add(:nonessential_email_banlist, type: :json)
    config.add(:otp_delivery_blocklist_findtime, type: :integer)
    config.add(:otp_delivery_blocklist_maxretry, type: :integer)
    config.add(:otp_valid_for, type: :integer)
    config.add(:otps_per_ip_limit, type: :integer)
    config.add(:otps_per_ip_period, type: :integer)
    config.add(:otps_per_ip_track_only_mode, type: :boolean)
    config.add(:vendor_status_acuant, type: :symbol, enum: VENDOR_STATUS_OPTIONS)
    config.add(:vendor_status_lexisnexis_instant_verify, type: :symbol, enum: VENDOR_STATUS_OPTIONS)
    config.add(:vendor_status_lexisnexis_trueid, type: :symbol, enum: VENDOR_STATUS_OPTIONS)
    config.add(:vendor_status_sms, type: :symbol, enum: VENDOR_STATUS_OPTIONS)
    config.add(:vendor_status_voice, type: :symbol, enum: VENDOR_STATUS_OPTIONS)
    config.add(:outbound_connection_check_retry_count, type: :integer)
    config.add(:outbound_connection_check_timeout, type: :integer)
    config.add(:outbound_connection_check_url)
    config.add(:participate_in_dap, type: :boolean)
    config.add(:partner_api_bucket_prefix, type: :string)
    config.add(:password_max_attempts, type: :integer)
    config.add(:password_pepper, type: :string)
    config.add(:personal_key_retired, type: :boolean)
    config.add(:phone_confirmation_max_attempts, type: :integer)
    config.add(:phone_confirmation_max_attempt_window_in_minutes, type: :integer)
    config.add(:phone_setups_per_ip_limit, type: :integer)
    config.add(:phone_setups_per_ip_period, type: :integer)
    config.add(:pii_lock_timeout_in_minutes, type: :integer)
    config.add(:pinpoint_sms_configs, type: :json)
    config.add(:pinpoint_sms_sender_id, type: :string, allow_nil: true)
    config.add(:pinpoint_voice_configs, type: :json)
    config.add(:piv_cac_service_url)
    config.add(:piv_cac_service_timeout, type: :float)
    config.add(:piv_cac_verify_token_secret)
    config.add(:piv_cac_verify_token_url)
    config.add(:phone_setups_per_ip_track_only_mode, type: :boolean)
    config.add(:platform_authentication_enabled, type: :boolean)
    config.add(:poll_rate_for_verify_in_seconds, type: :integer)
    config.add(:proofer_mock_fallback, type: :boolean)
    config.add(:proofing_send_partial_dob, type: :boolean)
    config.add(:proof_address_max_attempts, type: :integer)
    config.add(:proof_address_max_attempt_window_in_minutes, type: :integer)
    config.add(:proof_ssn_max_attempts, type: :integer)
    config.add(:proof_ssn_max_attempt_window_in_minutes, type: :integer)
    config.add(:push_notifications_enabled, type: :boolean)
    config.add(:pwned_passwords_file_path, type: :string)
    config.add(:rack_mini_profiler, type: :boolean)
    config.add(:rack_timeout_service_timeout_seconds, type: :integer)
    config.add(:rails_mailer_previews_enabled, type: :boolean)
    config.add(:reauthn_window, type: :integer)
    config.add(:recovery_code_length, type: :integer)
    config.add(:recurring_jobs_disabled_names, type: :json)
    config.add(:redis_irs_attempt_api_url)
    config.add(:redis_throttle_url)
    config.add(:redis_url)
    config.add(:reg_confirmed_email_max_attempts, type: :integer)
    config.add(:reg_confirmed_email_window_in_minutes, type: :integer)
    config.add(:reg_unconfirmed_email_max_attempts, type: :integer)
    config.add(:reg_unconfirmed_email_window_in_minutes, type: :integer)
    config.add(:remember_device_expiration_hours_aal_1, type: :integer)
    config.add(:remember_device_expiration_hours_aal_2, type: :integer)
    config.add(:report_timeout, type: :integer)
    config.add(:requests_per_ip_cidr_allowlist, type: :comma_separated_string_list)
    config.add(:requests_per_ip_limit, type: :integer)
    config.add(:requests_per_ip_path_prefixes_allowlist, type: :comma_separated_string_list)
    config.add(:requests_per_ip_period, type: :integer)
    config.add(:requests_per_ip_track_only_mode, type: :boolean)
    config.add(:reset_password_email_max_attempts, type: :integer)
    config.add(:reset_password_email_window_in_minutes, type: :integer)
    config.add(:risc_notifications_local_enabled, type: :boolean)
    config.add(:risc_notifications_active_job_enabled, type: :boolean)
    config.add(:risc_notifications_rate_limit_interval, type: :integer)
    config.add(:risc_notifications_rate_limit_max_requests, type: :integer)
    config.add(:risc_notifications_rate_limit_overrides, type: :json)
    config.add(:risc_notifications_request_timeout, type: :integer)
    config.add(:ruby_workers_idv_enabled, type: :boolean)
    config.add(:rules_of_use_horizon_years, type: :integer)
    config.add(:rules_of_use_updated_at, type: :timestamp)
    config.add(:s3_public_reports_enabled, type: :boolean)
    config.add(:s3_report_bucket_prefix, type: :string)
    config.add(:s3_report_public_bucket_prefix, type: :string)
    config.add(:s3_reports_enabled, type: :boolean)
    config.add(:saml_endpoint_configs, type: :json, options: { symbolize_names: true })
    config.add(:saml_secret_rotation_enabled, type: :boolean)
    config.add(:scrypt_cost, type: :string)
    config.add(:secret_key_base, type: :string)
    config.add(:seed_agreements_data, type: :boolean)
    config.add(:select_multiple_mfa_options, type: :boolean)
    config.add(:service_provider_request_ttl_hours, type: :integer)
    config.add(:session_check_delay, type: :integer)
    config.add(:session_check_frequency, type: :integer)
    config.add(:session_encryption_key, type: :string)
    config.add(:session_encryptor_alert_enabled, type: :boolean)
    config.add(:session_encryptor_v2_enabled, type: :boolean)
    config.add(:session_timeout_in_minutes, type: :integer)
    config.add(:session_timeout_warning_seconds, type: :integer)
    config.add(:session_total_duration_timeout_in_minutes, type: :integer)
    config.add(:set_remember_device_session_expiration, type: :boolean)
    config.add(:show_user_attribute_deprecation_warnings, type: :boolean)
    config.add(:skip_encryption_allowed_list, type: :json)
    config.add(:sp_handoff_bounce_max_seconds, type: :integer)
    config.add(:sps_over_quota_limit_notify_email_list, type: :json)
    config.add(:state_tracking_enabled, type: :boolean)
    config.add(:telephony_adapter, type: :string)
    config.add(:test_ssn_allowed_list, type: :comma_separated_string_list)
    config.add(:totp_code_interval, type: :integer)
    config.add(:unauthorized_scope_enabled, type: :boolean)
    config.add(:use_dashboard_service_providers, type: :boolean)
    config.add(:use_kms, type: :boolean)
    config.add(:usps_confirmation_max_days, type: :integer)
    config.add(:usps_ipp_password, type: :string)
    config.add(:usps_ipp_root_url, type: :string)
    config.add(:usps_ipp_sponsor_id, type: :string)
    config.add(:usps_ipp_username, type: :string)
    config.add(:usps_ipp_request_timeout, type: :integer)
    config.add(:usps_upload_enabled, type: :boolean)
    config.add(:gpo_allowed_for_strict_ial2, type: :boolean)
    config.add(:usps_upload_sftp_directory, type: :string)
    config.add(:usps_upload_sftp_host, type: :string)
    config.add(:usps_upload_sftp_password, type: :string)
    config.add(:usps_upload_sftp_timeout, type: :integer)
    config.add(:usps_upload_sftp_username, type: :string)
    config.add(:valid_authn_contexts, type: :json)
    config.add(:verification_errors_report_configs, type: :json)
    config.add(:verify_gpo_key_attempt_window_in_minutes, type: :integer)
    config.add(:verify_gpo_key_max_attempts, type: :integer)
    config.add(:verify_personal_key_attempt_window_in_minutes, type: :integer)
    config.add(:verify_personal_key_max_attempts, type: :integer)
    config.add(:voice_otp_pause_time)
    config.add(:voice_otp_speech_rate)
    config.add(:voip_allowed_phones, type: :json)
    config.add(:voip_block, type: :boolean)
    config.add(:voip_check, type: :boolean)

    @store = RedactedStruct.new('IdentityConfig', *config.written_env.keys, keyword_init: true).
      new(**config.written_env)
  end
end
