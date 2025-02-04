class UspsInPersonProofer
  attr_reader :token, :token_expires_at

  PostOffice = Struct.new(
    :distance, :address, :city, :phone, :name, :zip_code, :state, keyword_init: true
  )

  # Makes HTTP request to get nearby in-person proofing facilities
  # Requires address, city, state and zip code.
  # The PostOffice objects have a subset of the fields
  # returned by the API.
  # @param location [Object]
  # @return [Array<PostOffice>] Facility locations
  def request_facilities(location)
    url = "#{root_url}/ivs-ippaas-api/IPPRest/resources/rest/getIppFacilityList"
    body = {
      sponsorID: sponsor_id,
      streetAddress: location.address,
      city: location.city,
      state: location.state,
      zipCode: location.zip_code,
    }

    resp = faraday.post(url, body, dynamic_headers)

    resp.body['postOffices'].map do |post_office|
      PostOffice.new(
        distance: post_office['distance'],
        address: post_office['streetAddress'],
        city: post_office['city'],
        phone: post_office['phone'],
        name: post_office['name'],
        zip_code: post_office['zip5'],
        state: post_office['state'],
      )
    end
  end

  # Makes HTTP request to enroll an applicant in in-person proofing.
  # Requires first name, last name, address, city, state, zip code, email address and a generated
  # unique ID. The unique ID must be no longer than 18 characters.
  # USPS sends an email to the email address with instructions and the enrollment code.
  # The API response also includes the enrollment code which should be
  # stored with the unique ID to be able to request the status of proofing.
  # @param applicant [Object]
  # @return [Hash] API response
  def request_enroll(applicant)
    url = "#{root_url}/ivs-ippaas-api/IPPRest/resources/rest/optInIPPApplicant"
    body = {
      sponsorID: sponsor_id,
      uniqueID: applicant.unique_id,
      firstName: applicant.first_name,
      lastName: applicant.last_name,
      streetAddress: applicant.address,
      city: applicant.city,
      state: applicant.state,
      zipCode: applicant.zip_code,
      emailAddress: applicant.email,
      IPPAssuranceLevel: '1.5',
    }

    faraday.post(url, body, dynamic_headers).body
  end

  # Makes HTTP request to retrieve proofing status
  # Requires the applicant's enrollment code and unique ID.
  # When proofing is complete the API returns 200 status.
  # If the applicant has not been to the post office, has proofed recently,
  # or there is another issue, the API returns a 400 status with an error message.
  # @param unique_id [String]
  # @param enrollment_code [String]
  # @return [Hash] API response
  def request_proofing_results(unique_id, enrollment_code)
    url = "#{root_url}/ivs-ippaas-api/IPPRest/resources/rest/getProofingResults"
    body = {
      sponsorID: sponsor_id,
      uniqueID: unique_id,
      enrollmentCode: enrollment_code,
    }

    faraday.post(url, body, dynamic_headers).body
  end

  # Makes HTTP request to retrieve enrollment code
  # If an applicant has a currently valid enrollment code, it will be returned.
  # If they do not, a new one will be generated and returned. USPS sends the applicant an email with
  # instructions and the enrollment code.
  # Requires the applicant's unique ID.
  # @param unique_id [String]
  # @return [Hash] API response
  def request_enrollment_code(unique_id)
    url = "#{root_url}/ivs-ippaas-api/IPPRest/resources/rest/requestEnrollmentCode"
    body = {
      sponsorID: sponsor_id,
      uniqueID: unique_id,
    }

    faraday.post(url, body, dynamic_headers).body
  end

  # Makes a request to retrieve a new OAuth token
  # and modifies self to store the token and when
  # it expires (15 minutes).
  # @return [String] the token
  def retrieve_token!
    body = request_token
    @token_expires_at = Time.zone.now + body['expires_in']
    @token = "#{body['token_type']} #{body['access_token']}"
  end

  def token_valid?
    @token.present? && @token_expires_at.present? && @token_expires_at.future?
  end

  private

  def faraday
    Faraday.new(headers: request_headers) do |conn|
      conn.options.timeout = IdentityConfig.store.usps_ipp_request_timeout
      conn.options.read_timeout = IdentityConfig.store.usps_ipp_request_timeout
      conn.options.open_timeout = IdentityConfig.store.usps_ipp_request_timeout
      conn.options.write_timeout = IdentityConfig.store.usps_ipp_request_timeout

      # Raise an error subclassing Faraday::Error on 4xx, 5xx, and malformed responses
      # Note: The order of this matters for parsing the error response body.
      conn.response :raise_error

      # Log request method and URL, excluding headers and body
      conn.response :logger, nil, { headers: false, bodies: false }

      # Convert body to JSON
      conn.request :json

      # Parse JSON responses
      conn.response :json
    end
  end

  # Retrieve the OAuth2 token (if needed) and then pass
  # the headers to an arbitrary block of code as a Hash.
  #
  # Returns the same value returned by that block of code.
  def dynamic_headers
    retrieve_token! unless token_valid?

    {
      'Authorization' => @token,
      'RequestID' => request_id,
    }
  end

  # Makes HTTP request to authentication endpoint and
  # returns the token and when it expires (15 minutes).
  # @return [Hash] API response
  def request_token
    url = "#{root_url}/oauth/authenticate"
    body = {
      username: IdentityConfig.store.usps_ipp_username,
      password: IdentityConfig.store.usps_ipp_password,
      grant_type: 'implicit',
      response_type: 'token',
      client_id: '424ada78-62ae-4c53-8e3a-0b737708a9db',
      scope: 'ivs.ippaas.apis',
    }

    faraday.post(url, body).body
  end

  def root_url
    IdentityConfig.store.usps_ipp_root_url
  end

  def sponsor_id
    IdentityConfig.store.usps_ipp_sponsor_id.to_i
  end

  def request_id
    SecureRandom.uuid
  end

  def request_headers
    { 'Content-Type' => 'application/json; charset=utf-8' }
  end
end
