RSpec.describe BankApi do
  it 'has a version number' do
    expect(BankApi::VERSION).not_to be nil
  end

  it 'calls BancoDeChileCompanyClient' do
    expect_any_instance_of(BankApi::Clients::BancoDeChileCompanyClient)
      .to receive(:get_recent_deposits)

    BankApi.get_bdc_recent_company_deposits
  end

  it 'calls BancoSecurity::CompanyClient' do
    expect_any_instance_of(BankApi::Clients::BancoSecurity::CompanyClient)
      .to receive(:get_recent_deposits)

    BankApi::BancoSecurity.get_recent_company_deposits
  end
end
