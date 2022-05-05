#!/usr/bin/env ruby
require 'jwt'
require 'net/http'

payload = { inherited_proofing_auth: 'mocked-auth-code-for-testing', exp: 1.day.from_now.to_i }
private_key = AppArtifacts.store.oidc_private_key
token = JWT.encode(payload, private_key, 'RS256')

uri = URI 'https://dev-api.va.gov/inherited_proofing/user_attributes'
headers = { 'Authorization': "Bearer #{token}" }

request = Net::HTTP.get_response(uri, headers)
puts request.body
