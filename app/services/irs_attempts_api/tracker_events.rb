module IrsAttemptsApi
  module TrackerEvents
    # @param [String] email The submitted email address
    # @param [Boolean] success True if the email and password matched
    # A user has submitted an email address and password for authentication
    def email_and_password_auth(email:, success:)
      track_event(
        :email_and_password_auth,
        email: email,
        success: success,
      )
    end

    def logout(user_uuid:, unique_session_id:, success:)
      track_event(
        :logout,
        user_uuid: user_uuid,
        unique_session_id: unique_session_id,
        success: success
      )
    end
  end
end
