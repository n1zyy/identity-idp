module Idv
  module Steps
    module Ipp
      class VerifyStep < VerifyBaseStep
        STEP_INDICATOR_STEP = :verify_info
        def call
          # WILLFIX: (LG-6498) make a call to Instant Verify before allowing the user to continue
          save_legacy_state
          delete_pii
        end

        def extra_view_variables
          {
            pii: pii,
            step_url: method(:idv_in_person_step_url),
          }
        end
      end
    end
  end
end
