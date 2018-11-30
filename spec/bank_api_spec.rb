RSpec.describe BankApi do
  it 'has a version number' do
    expect(BankApi::VERSION).not_to be nil
  end

  it 'calls BancoDeChileCompanyClient' do
    expect_any_instance_of(BankApi::Clients::BancoDeChileCompanyClient)
      .to receive(:get_recent_deposits)

    BankApi.get_bdc_recent_company_deposits
  end

  it 'calls BancoDeChileCompanyClient' do
    expect_any_instance_of(BankApi::Clients::BancoDeChileCompanyClient)
      .to receive(:get_recent_withdrawals)

    BankApi.get_bdc_recent_company_withdrawals
  end

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
end
