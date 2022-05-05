#!/usr/bin/env ruby

require 'jwt'
require 'net/http'

# Script to test connection to VA API, can be removed once we create code inside the IDV flow
class VaApiTest
  def run
    uri = URI 'https://staging-api.va.gov/inherited_proofing/user_attributes'
    headers = { Authorization: "Bearer #{jwt_token}" }

    response = Net::HTTP.get_response(uri, headers)
    puts response.body
  end

  private

  def jwt_token
    payload = { inherited_proofing_auth: 'mocked-auth-code-for-testing', exp: 1.day.from_now.to_i }
    private_key = AppArtifacts.store.oidc_private_key
    JWT.encode(payload, private_key, 'RS256')
  end
end

VaApiTest.new.run if $PROGRAM_NAME == __FILE__
