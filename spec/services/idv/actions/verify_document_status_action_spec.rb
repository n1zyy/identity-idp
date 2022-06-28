require 'rails_helper'

describe Idv::Actions::VerifyDocumentStatusAction do
  include IdvHelper

  let(:user) { create(:user) }
  let(:sp_session) { {} }
  let(:session) { { 'idv/doc_auth' => {}, sp: sp_session } }
  let(:controller) do
    instance_double(Idv::DocAuthController, url_options: {}, session: session, analytics: analytics)
  end
  let(:flow) { Idv::Flows::DocAuthFlow.new(controller, session, 'idv/doc_auth') }
  let(:analytics) { FakeAnalytics.new }
  let(:billed) { true }
  let(:attention_with_barcode) { false }
  let(:result) do
    {
      doc_auth_result: 'Passed',
      success: true,
      errors: {},
      exception: nil,
      billed: billed,
      attention_with_barcode: attention_with_barcode,
    }
  end
  let(:pii) { Idp::Constants::MOCK_IDV_APPLICANT }
  let(:async_state) do
    DocumentCaptureSessionAsyncResult.new(
      status: DocumentCaptureSessionAsyncResult::DONE,
      result: result,
      pii: pii,
    )
  end
  let(:issuer) { 'urn:gov:gsa:openidconnect:sp:test_cookie' }
  let(:sp) { create(:service_provider, issuer: issuer) }

  subject { described_class.new(flow) }

  describe '#call' do
    context 'successful async result' do
      before do
        allow(subject).to receive(:async_state).and_return(async_state)
        allow(subject).to receive(:current_user).and_return(user)
        allow(subject).to receive(:current_sp).and_return(sp)
      end

      it 'calls analytics to log the successful event' do
        subject.call

        expect(analytics).to have_logged_event(
          'IdV: doc auth image upload vendor pii validation',
          success: true,
          errors: {},
        )
      end

      it 'adds costs' do
        subject.call

        expect(SpCost.where(issuer: issuer).map(&:cost_type)).to contain_exactly(
          'acuant_front_image',
          'acuant_back_image',
          'acuant_result',
        )
      end

      it 'assigns session variables' do
        subject.call

        expect(session['idv/doc_auth']).to include(
          had_barcode_read_failure: false,
          pii_from_doc: pii.merge(uuid: user.uuid, uuid_prefix: sp.app_id, phone: nil),
        )
      end

      context 'unbilled' do
        let(:billed) { false }

        it 'adds costs' do
          subject.call

          expect(SpCost.where(issuer: issuer).map(&:cost_type)).to contain_exactly(
            'acuant_front_image',
            'acuant_back_image',
          )
        end
      end

      context 'with barcode attention result' do
        let(:attention_with_barcode) { true }

        it 'assigns session variables' do
          subject.call

          expect(session['idv/doc_auth']).to include(
            had_barcode_read_failure: true,
            pii_from_doc: pii.merge(uuid: user.uuid, uuid_prefix: sp.app_id, phone: nil),
          )
        end
      end

      context 'ial2 strict' do
        let(:sp_session) { { ial2_strict: true } }

        before do
          allow(IdentityConfig.store).to receive(:liveness_checking_enabled).and_return(true)
        end

        it 'adds costs' do
          subject.call

          expect(SpCost.where(issuer: issuer).map(&:cost_type)).to contain_exactly(
            'acuant_front_image',
            'acuant_back_image',
            'acuant_selfie',
            'acuant_result',
          )
        end
      end
    end

    it 'calls analytics if missing from no document capture session' do
      subject.call

      expect(analytics).to have_logged_event('Proofing Document Result Missing', {})
      expect(analytics).to have_logged_event(
        'Doc Auth Async',
        error: 'failed to load verify_document_capture_session',
        uuid: nil,
      )
    end

    it 'calls analytics if missing from no result in document capture session' do
      verify_document_capture_session = DocumentCaptureSession.new(
        uuid: 'uuid',
        result_id: 'result_id',
        user: create(:user),
      )

      expect(subject).to receive(:verify_document_capture_session).
        and_return(verify_document_capture_session).at_least(:once)
      subject.call

      expect(analytics).to have_logged_event('Proofing Document Result Missing', {})
      expect(analytics).to have_logged_event(
        'Doc Auth Async',
        error: 'failed to load async result',
        uuid: verify_document_capture_session.uuid,
        result_id: verify_document_capture_session.result_id,
      )
    end
  end
end
