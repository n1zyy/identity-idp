import { forwardRef, useCallback } from 'react';
import type { ForwardedRef } from 'react';
import Cleave from 'cleave.js/react';
import type { ReactInstanceWithCleave } from 'cleave.js/react/props';
import { t } from '@18f/identity-i18n';
import { ValidatedField } from '@18f/identity-validated-field';
import type { ValidatedFieldValidator } from '@18f/identity-validated-field';

/**
 * Internal Cleave.js React instance API methods.
 */
interface CleaveInstanceInternalAPI {
  updateValueState: () => void;
}

interface PersonalKeyInputProps {
  /**
   * The personal key to initially render the form with. This value is used when the user has
   * entered a partial personal key and clicked the "back" button.
   */
  value?: string;

  /**
   * The correct personal key to validate against.
   */
  expectedValue?: string;

  /**
   * Callback invoked when the value of the input has changed.
   */
  onChange?: (nextValue: string) => void;
}

/**
 * Normalize an input value for validation comparison.
 *
 * @param string Denormalized value.
 *
 * @return Normalized value.
 */
const normalize = (string: string) => string.toLowerCase().replace(/o/g, '0').replace(/[il]/g, '1');

function PersonalKeyInput(
  { value, expectedValue, onChange = () => {} }: PersonalKeyInputProps,
  ref: ForwardedRef<HTMLElement>,
) {
  const validate = useCallback<ValidatedFieldValidator>(
    (personalKey) => {
      if (expectedValue && normalize(personalKey) !== normalize(expectedValue)) {
        throw new Error(t('users.personal_key.confirmation_error'));
      }
    },
    [expectedValue],
  );

  return (
    <ValidatedField validate={validate}>
      <Cleave
        onInit={(owner) => {
          (owner as ReactInstanceWithCleave & CleaveInstanceInternalAPI).updateValueState();
        }}
        value={value}
        options={{
          blocks: [4, 4, 4, 4],
          delimiter: '-',
        }}
        htmlRef={(cleaveRef) => typeof ref === 'function' && ref(cleaveRef)}
        aria-label={t('forms.personal_key.confirmation_label')}
        autoComplete="off"
        className="width-full field font-family-mono text-uppercase"
        pattern="[a-zA-Z0-9-]+"
        spellCheck={false}
        type="text"
        onInput={(event) => onChange((event.target as HTMLInputElement).value)}
      />
    </ValidatedField>
  );
}

export default forwardRef(PersonalKeyInput);
