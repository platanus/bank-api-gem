module PincersHelpers
  def expect_to_set(browser, query:, value: nil)
    expect(browser).to receive(:search).with(query).and_return(element_mock)
    if value.nil?
      expect(element_mock).to receive(:set)
    else
      expect(element_mock).to receive(:set).with(value)
    end
  end

  def element_mock
    @element_mock ||= begin
      element_mock = double
      allow(element_mock).to receive(:set)
      allow(element_mock).to receive(:click)
      element_mock
    end
  end
end
