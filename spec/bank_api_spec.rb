RSpec.describe BankApi do
  it 'has a version number' do
    expect(BankApi::VERSION).not_to be nil
  end

  it 'calls BancoDeChileCompanyClient' do
    expect_any_instance_of(BankApi::Clients::BancoDeChileCompanyClient)
      .to receive(:get_recent_deposits)

    BankApi.get_bdc_recent_company_deposits
  end

  describe "BancoSecurity" do
    it 'calls get_recent_deposits on BancoSecurity::CompanyClient' do
      expect_any_instance_of(BankApi::Clients::BancoSecurity::CompanyClient)
        .to receive(:get_recent_deposits)

      BankApi::BancoSecurity.get_recent_company_deposits
    end

    it 'calls transfer on  BancoSecurity::CompanyClient' do
      expect_any_instance_of(BankApi::Clients::BancoSecurity::CompanyClient)
        .to receive(:transfer)

      BankApi::BancoSecurity.company_transfer({})
    end

    it 'calls batch_transfers BancoSecurity::CompanyClient' do
      expect_any_instance_of(BankApi::Clients::BancoSecurity::CompanyClient)
        .to receive(:batch_transfers)

      BankApi::BancoSecurity.company_batch_transfers([])
    end

    it 'calls execute_pending_transfer BancoSecurity::CompanyClient' do
      expect_any_instance_of(BankApi::Clients::BancoSecurity::CompanyClient)
        .to receive(:pending_transfer).with('trx_id', {})

      BankApi::BancoSecurity.pending_company_transfer('trx_id', {})
    end

    context "with_credentials" do
      let(:credentials) { { user_rut: "2-k", password: "password", company_rut: "1-k" } }

      it 'calls get_recent_deposits on BancoSecurity::CompanyClient' do
        expect_any_instance_of(BankApi::Clients::BancoSecurity::CompanyClient)
          .to receive(:get_recent_deposits)

        BankApi::BancoSecurity.with_credentials(**credentials).get_recent_company_deposits
      end

      it 'calls transfer on  BancoSecurity::CompanyClient' do
        expect_any_instance_of(BankApi::Clients::BancoSecurity::CompanyClient)
          .to receive(:transfer)

        BankApi::BancoSecurity.with_credentials(**credentials).company_transfer({})
      end

      it 'calls batch_transfers BancoSecurity::CompanyClient' do
        expect_any_instance_of(BankApi::Clients::BancoSecurity::CompanyClient)
          .to receive(:batch_transfers)

        BankApi::BancoSecurity.with_credentials(**credentials).company_batch_transfers([])
      end
    end
  end
end
