# coding: utf-8

module BankApi::Clients::BancoSecurity
  module Deposits
    DATE_COLUMN = 0
    RUT_COLUMN = 2
    AMOUNT_COLUMN = 5

    NUMBER_OF_COLUMNS = 7

    def select_deposits_range
      browser.search('.BusquedaPorDefectoRecibida a:contains("búsqueda avanzada")').click
      browser.search('#RadioEntreFechasRecibido').click
      browser.search('#datePickerInicioRecibidas').set deposit_range[:start]
      browser.search('#datePickerFinRecibido').set deposit_range[:end]
      browser.search('.ContenedorSubmitRecibidas .btn_buscar').click
      set_page_size
      wait_for_deposits_fetch
    end

    def wait_for_deposits_fetch
      goto_frame query: '#mainFrame'
      goto_frame query: 'iframe[name="central"]', should_reset: false
      wait('.k-loading-image') { browser.search('.k-loading-image').any? }
      wait('.k-loading-image') { browser.search('.k-loading-image').none? }
    end

    def wait_for_next_page(last_seen_deposit)
      wait(".k-pager-info") { last_seen_deposit < last_deposit_in_current_page }
    end

    def extract_deposits_from_html
      deposits = []

      return deposits unless any_deposits?

      deposits += deposits_from_page
      last_seen_deposit = last_deposit_in_current_page
      ((total_deposits - 1) / @page_size).times do
        goto_next_page
        wait_for_next_page(last_seen_deposit)
        last_seen_deposit = last_deposit_in_current_page

        deposits += deposits_from_page
      end

      validate_deposits(deposits, last_seen_deposit)

      deposits.sort_by { |d| d[:date] }
    end

    def deposits_from_page
      deposits = []
      deposit = {}
      browser.search('#gridPrincipalRecibidas tbody td').each_with_index do |div, index|
        if (index % NUMBER_OF_COLUMNS) == RUT_COLUMN
          deposit[:rut] = div.text
        elsif (index % NUMBER_OF_COLUMNS) == DATE_COLUMN
          deposit[:date] = Date.parse div.text
        elsif (index % NUMBER_OF_COLUMNS) == AMOUNT_COLUMN
          deposit[:amount] = div.text.gsub(/[\. $]/, '').to_i
        elsif ((index + 1) % NUMBER_OF_COLUMNS).zero?
          deposits << deposit
          deposit = {}
        end
      end
      deposits
    end

    def set_page_size
      browser.search('[aria-owns="pagerSettingRecibidas_listbox"]').click
      sleep 0.1
      browser.search('.k-animation-container.km-popup li').find do |li|
        li.text == @page_size.to_s
      end.click
      wait('.k-loading-image') { browser.search('.k-loading-image').any? }
      wait('.k-loading-image') { browser.search('.k-loading-image').none? }
    end

    def last_deposit_in_current_page
      pages_info = wait(".k-pager-info")
      matches = pages_info.text.match(/(\d+)[a-z\s-]+(\d+)[a-z\s-]+(\d+)/)
      matches[2].to_i
    end

    def total_deposits
      pages_info = wait(".k-pager-info")
      matches = pages_info.text.match(/(\d+)[a-z\s-]+(\d+)[a-z\s-]+(\d+)/)
      matches[3].to_i
    end

    def goto_next_page
      browser.search('#gridPrincipalRecibidas a.k-link[title="Go to the next page"]').click
    end

    def deposit_range
      @deposit_range ||= begin
        timezone = Timezone['America/Santiago']
        {
          start: (timezone.utc_to_local(Time.now).to_date - @days_to_check).strftime('%d/%m/%Y'),
          end: timezone.utc_to_local(Time.now).to_date.strftime('%d/%m/%Y')
        }
      end
    end

    def any_deposits?
      browser.search(
        ".k-label:contains('No se han encontrado transacciones para la búsqueda seleccionada.')"
      ).none?
    end

    def validate_deposits(deposits, last_seen_deposit)
      total_deposits_ = total_deposits
      unless deposits.count == total_deposits_
        raise BankApi::Deposit::QuantityError, "Expected #{total_deposits_} deposits," +
          " got #{deposits.count}."
      end

      unless last_seen_deposit == total_deposits_
        raise BankApi::Deposit::PaginationError, "Expected to fetch #{total_deposits_} deposits," +
          " the last seen deposit was nº #{last_seen_deposit}."
      end
    end
  end
end
