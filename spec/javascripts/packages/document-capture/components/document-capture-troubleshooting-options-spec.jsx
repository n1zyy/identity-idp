import { render } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import {
  HelpCenterContextProvider,
  ServiceProviderContextProvider,
} from '@18f/identity-document-capture';
import { FlowContext } from '@18f/identity-verify-flow';
import DocumentCaptureTroubleshootingOptions from '@18f/identity-document-capture/components/document-capture-troubleshooting-options';

describe('DocumentCaptureTroubleshootingOptions', () => {
  const helpCenterRedirectURL = 'https://example.com/redirect/';
  const inPersonURL = 'https://example.com/some/idv/ipp/url';
  const serviceProviderContext = {
    name: 'Example SP',
    failureToProofURL: 'http://example.test/url/to/failure-to-proof',
  };
  const wrappers = {
    helpCenterContext: ({ children }) => (
      <HelpCenterContextProvider value={{ helpCenterRedirectURL }}>
        {children}
      </HelpCenterContextProvider>
    ),
    helpCenterAndServiceProviderContext: ({ children }) => (
      <HelpCenterContextProvider value={{ helpCenterRedirectURL }}>
        <ServiceProviderContextProvider value={serviceProviderContext}>
          {children}
        </ServiceProviderContextProvider>
      </HelpCenterContextProvider>
    ),
  };

  it('renders troubleshooting options', () => {
    const { getAllByRole } = render(<DocumentCaptureTroubleshootingOptions />, {
      wrapper: wrappers.helpCenterContext,
    });

    const links = /** @type {HTMLAnchorElement[]} */ (getAllByRole('link'));

    expect(links).to.have.lengthOf(2);
    expect(links[0].textContent).to.equal(
      'idv.troubleshooting.options.doc_capture_tips links.new_window',
    );
    expect(links[0].getAttribute('href')).to.equal(
      'https://example.com/redirect/?category=verify-your-identity&article=how-to-add-images-of-your-state-issued-id&location=document_capture_troubleshooting_options',
    );
    expect(links[0].target).to.equal('_blank');
    expect(links[1].textContent).to.equal(
      'idv.troubleshooting.options.supported_documents links.new_window',
    );
    expect(links[1].getAttribute('href')).to.equal(
      'https://example.com/redirect/?category=verify-your-identity&article=accepted-state-issued-identification&location=document_capture_troubleshooting_options',
    );
    expect(links[1].target).to.equal('_blank');
  });

  context('with associated service provider', () => {
    it('renders troubleshooting options', () => {
      const { getAllByRole } = render(<DocumentCaptureTroubleshootingOptions />, {
        wrapper: wrappers.helpCenterAndServiceProviderContext,
      });

      const links = /** @type {HTMLAnchorElement[]} */ (getAllByRole('link'));

      expect(links).to.have.lengthOf(3);
      expect(links[0].textContent).to.equal(
        'idv.troubleshooting.options.doc_capture_tips links.new_window',
      );
      expect(links[0].getAttribute('href')).to.equal(
        'https://example.com/redirect/?category=verify-your-identity&article=how-to-add-images-of-your-state-issued-id&location=document_capture_troubleshooting_options',
      );
      expect(links[0].target).to.equal('_blank');
      expect(links[1].textContent).to.equal(
        'idv.troubleshooting.options.supported_documents links.new_window',
      );
      expect(links[1].getAttribute('href')).to.equal(
        'https://example.com/redirect/?category=verify-your-identity&article=accepted-state-issued-identification&location=document_capture_troubleshooting_options',
      );
      expect(links[1].target).to.equal('_blank');
      expect(links[2].textContent).to.equal(
        'idv.troubleshooting.options.get_help_at_sp links.new_window',
      );
      expect(links[2].href).to.equal(
        'http://example.test/url/to/failure-to-proof?location=document_capture_troubleshooting_options',
      );
      expect(links[2].target).to.equal('_blank');
    });

    context('with location prop', () => {
      it('appends location to links', () => {
        const { getAllByRole } = render(
          <DocumentCaptureTroubleshootingOptions location="custom" />,
          {
            wrapper: wrappers.helpCenterAndServiceProviderContext,
          },
        );

        const links = /** @type {HTMLAnchorElement[]} */ (getAllByRole('link'));

        expect(links[0].href).to.equal(
          'https://example.com/redirect/?category=verify-your-identity&article=how-to-add-images-of-your-state-issued-id&location=custom',
        );
        expect(links[1].href).to.equal(
          'https://example.com/redirect/?category=verify-your-identity&article=accepted-state-issued-identification&location=custom',
        );
        expect(links[2].href).to.equal(
          'http://example.test/url/to/failure-to-proof?location=custom',
        );
      });
    });
  });

  context('with heading prop', () => {
    it('shows heading text', () => {
      const { getByRole } = render(
        <DocumentCaptureTroubleshootingOptions heading="custom heading" />,
      );

      expect(getByRole('heading', { name: 'custom heading' })).to.exist();
    });
  });

  context('in person proofing links', () => {
    context('no errors and no inPersonURL', () => {
      it('has no IPP information', () => {
        const { queryByText } = render(<DocumentCaptureTroubleshootingOptions />);

        expect(queryByText('components.troubleshooting_options.new_feature')).to.not.exist();
      });
    });

    context('hasErrors but no inPersonURL', () => {
      it('has no IPP information', () => {
        const { queryByText } = render(<DocumentCaptureTroubleshootingOptions hasErrors />);

        expect(queryByText('components.troubleshooting_options.new_feature')).to.not.exist();
      });
    });

    context('hasErrors and inPersonURL', () => {
      const wrapper = ({ children }) => (
        <FlowContext.Provider value={{ inPersonURL }}>{children}</FlowContext.Provider>
      );

      it('has links to IPP information', async () => {
        const { getByText, getAllByRole } = render(
          <DocumentCaptureTroubleshootingOptions hasErrors />,
          { wrapper },
        );

        expect(getByText('components.troubleshooting_options.new_feature')).to.exist();

        const links = getAllByRole('link');
        const ippLink = links.find(({ href }) => href === inPersonURL);
        expect(ippLink).to.exist();

        window.onbeforeunload = () => {};
        await userEvent.click(ippLink);
        expect(window.onbeforeunload).not.to.exist();
      });
    });
  });

  context('with document tips hidden', () => {
    it('renders nothing', () => {
      const { container } = render(
        <DocumentCaptureTroubleshootingOptions showDocumentTips={false} />,
      );

      expect(container.innerHTML).to.be.empty();
    });

    context('with associated service provider', () => {
      it('renders troubleshooting options', () => {
        const { getAllByRole } = render(
          <DocumentCaptureTroubleshootingOptions showDocumentTips={false} />,
          {
            wrapper: wrappers.helpCenterAndServiceProviderContext,
          },
        );

        const links = /** @type {HTMLAnchorElement[]} */ (getAllByRole('link'));

        expect(links).to.have.lengthOf(1);
        expect(links[0].getAttribute('href')).to.equal(
          'http://example.test/url/to/failure-to-proof?location=document_capture_troubleshooting_options',
        );
      });
    });
  });
});
