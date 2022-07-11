#!/usr/bin/env ruby

require 'jwt'
require 'jwe'
require 'net/http'

# Script to test connection to VA API, can be removed once we create code inside the IDV flow
class VaApiTest
  def run
    uri = URI 'https://staging-api.va.gov/inherited_proofing/user_attributes'
    headers = { Authorization: "Bearer #{jwt_token}" }

    response = Net::HTTP.get_response(uri, headers)
    binding.pry
    decrypt_payload(response)
  end

  private

  def jwt_token
    payload = { inherited_proofing_auth: 'mocked-auth-code-for-testing', exp: 1.day.from_now.to_i }
    JWT.encode(payload, private_key, 'RS256')
  end

  def decrypt_payload(response)
    payload = JSON.parse(response.body)['data']
    JWE.decrypt(payload, private_key) if payload
  end

  def private_key
    if Identity::Hostdata.in_datacenter? || !File.exist?('tmp/va_ip.key')
      AppArtifacts.store.oidc_private_key
    else
      OpenSSL::PKey::RSA.new(File.read('tmp/va_ip.key'))
    end
  end
end

puts(VaApiTest.new.run) if $PROGRAM_NAME == __FILE__
