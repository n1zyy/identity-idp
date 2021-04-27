require 'rails_helper'

describe RegisterUserEmailForm do
  let(:analytics) { FakeAnalytics.new }
  subject { RegisterUserEmailForm.new(analytics: analytics) }

  it_behaves_like 'email validation'

  describe '#submit' do
    context 'when email is already taken' do
      it 'sets success to true to prevent revealing account existence' do
        existing_user = create(:user, :signed_up, email: 'taken@gmail.com')

        mailer = instance_double(ActionMailer::MessageDelivery)
        allow(UserMailer).to receive(:signup_with_your_email).
          with(existing_user, existing_user.email).and_return(mailer)
        allow(mailer).to receive(:deliver_now)

        extra = {
          email_already_exists: true,
          throttled: false,
          user_id: existing_user.uuid,
          domain_name: 'gmail.com',
        }

        result = instance_double(FormResponse)

        expect(FormResponse).to receive(:new).
          with(success: true, errors: {}, extra: extra).and_return(result)
        expect(subject.submit(email: 'TAKEN@gmail.com')).to eq result
        expect(subject.email).to eq 'taken@gmail.com'
        expect(mailer).to have_received(:deliver_now)
      end

      it 'creates throttle events after reaching throttle limit' do
        existing_user = create(:user, :signed_up, email: 'taken@example.com')

        (IdentityConfig.store.reg_confirmed_email_max_attempts + 1).times do
          subject.submit(email: 'TAKEN@example.com')
        end

        expect(analytics).to have_logged_event(
          Analytics::THROTTLER_RATE_LIMIT_TRIGGERED,
          throttle_type: :reg_confirmed_email,
        )
      end
    end

    context 'when email is already taken and existing user is unconfirmed' do
      it 'sends confirmation instructions to existing user' do
        user = create(:user, email: 'existing@test.com', confirmed_at: nil, uuid: '123')
        allow(User).to receive(:find_with_email).with(user.email).and_return(user)

        send_sign_up_email_confirmation = instance_double(SendSignUpEmailConfirmation)
        expect(send_sign_up_email_confirmation).to receive(:call)
        expect(SendSignUpEmailConfirmation).to receive(:new).with(
          user,
        ).and_return(send_sign_up_email_confirmation)

        extra = {
          email_already_exists: true,
          throttled: false,
          user_id: user.uuid,
          domain_name: 'test.com',
        }

        result = instance_double(FormResponse)

        expect(FormResponse).to receive(:new).
          with(success: true, errors: {}, extra: extra).and_return(result)
        expect(subject.submit(email: user.email)).to eq result
      end

      it 'creates throttle events after reaching throttle limit' do
        user = create(:user, email: 'test@example.com', confirmed_at: nil, uuid: '123')
        (IdentityConfig.store.reg_unconfirmed_email_max_attempts + 1).times do
          subject.submit(email: 'test@example.com')
        end

        expect(analytics).to have_logged_event(
          Analytics::THROTTLER_RATE_LIMIT_TRIGGERED,
          throttle_type: :reg_unconfirmed_email,
        )
      end
    end

    context 'when the email exists but is unconfirmed and on a confirmed user' do
      it 'is valid and sends a registration email for a new user' do
        old_user = create(:user)
        email_address = create(:email_address, user: old_user, confirmed_at: nil)

        send_sign_up_email_confirmation = instance_double(SendSignUpEmailConfirmation)
        expect(send_sign_up_email_confirmation).to receive(:call)
        expect(SendSignUpEmailConfirmation).to receive(:new).
          and_return(send_sign_up_email_confirmation)

        result = subject.submit(email: email_address.email)
        uuid = result.extra[:user_id]
        new_user = User.find_by(uuid: uuid)

        expect(new_user).to_not be_nil
        expect(new_user.id).to_not eq(old_user.id)
        expect(new_user.email_addresses.first.email).to eq(email_address.email)
      end
    end

    context 'when email is not already taken' do
      it 'is valid' do
        result = instance_double(FormResponse)
        allow(FormResponse).to receive(:new).and_return(result)
        submit_form = subject.submit(email: 'not_taken@gmail.com')
        extra = {
          email_already_exists: false,
          throttled: false,
          user_id: User.find_with_email('not_taken@gmail.com').uuid,
          domain_name: 'gmail.com',
        }

        expect(FormResponse).to have_received(:new).
          with(success: true, errors: {}, extra: extra)
        expect(submit_form).to eq result
      end

      it 'saves the user email_language for a valid form' do
        form = RegisterUserEmailForm.new(analytics: analytics)

        response = form.submit(email: 'not_taken@gmail.com', email_language: 'fr')
        expect(response).to be_success

        expect(User.find_with_email('not_taken@gmail.com').email_language).to eq('fr')
      end
    end

    context 'when email is invalid' do
      it 'returns false and adds errors to the form object' do
        errors = { email: [t('valid_email.validations.email.invalid')] }

        extra = {
          email_already_exists: false,
          throttled: false,
          user_id: 'anonymous-uuid',
          domain_name: 'invalid_email',
        }

        result = instance_double(FormResponse)

        expect(FormResponse).to receive(:new).
          with(success: false, errors: errors, extra: extra).and_return(result)
        expect(subject.submit(email: 'invalid_email')).to eq result
      end
    end

    context 'when request_id is invalid' do
      it 'returns unsuccessful and adds an error to the form object' do
        errors = { email: [t('sign_up.email.invalid_request')] }
        result = instance_double(FormResponse)
        allow(FormResponse).to receive(:new).and_return(result)
        submit_form = subject.submit(email: 'not_taken@gmail.com', request_id: 'fake_id')
        extra = {
          domain_name: 'gmail.com',
          email_already_exists: false,
          throttled: false,
          user_id: 'anonymous-uuid',
        }

        expect(FormResponse).to have_received(:new).
          with(errors: errors, extra: extra, success: false)
        expect(submit_form).to eq result
      end
    end

    context 'when request_id is valid' do
      it 'returns success with no errors' do
        sp_request = ServiceProviderRequestProxy.create(
          issuer: 'urn:gov:gsa:openidconnect:sp:sinatra',
          loa: 'http://idmanagement.gov/ns/assurance/loa/1',
          url: 'http://localhost:3000/openid_connect/authorize',
          uuid: SecureRandom.uuid,
        )
        request_id = sp_request.uuid
        result = instance_double(FormResponse)
        allow(FormResponse).to receive(:new).and_return(result)
        submit_form = subject.submit(email: 'not_taken@gmail.com', request_id: request_id)
        extra = {
          domain_name: 'gmail.com',
          email_already_exists: false,
          throttled: false,
          user_id: User.find_with_email('not_taken@gmail.com').uuid,
        }

        expect(FormResponse).to have_received(:new).
          with(errors: {}, extra: extra, success: true)
        expect(submit_form).to eq result
      end
    end

    context 'when request_id is blank' do
      it 'returns success with no errors' do
        result = instance_double(FormResponse)
        allow(FormResponse).to receive(:new).and_return(result)
        submit_form = subject.submit(email: 'not_taken@gmail.com', request_id: nil)
        extra = {
          domain_name: 'gmail.com',
          email_already_exists: false,
          throttled: false,
          user_id: User.find_with_email('not_taken@gmail.com').uuid,
        }

        expect(FormResponse).to have_received(:new).
          with(errors: {}, extra: extra, success: true)
        expect(submit_form).to eq result
      end
    end
  end
end
