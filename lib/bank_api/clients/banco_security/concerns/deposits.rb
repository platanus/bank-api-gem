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
      wait_for_deposits_fetch
    end

    def wait_for_deposits_fetch
      goto_frame query: '#mainFrame'
      goto_frame query: 'iframe[name="central"]', should_reset: false
      wait('.k-loading-image') { browser.search('.k-loading-image').count.zero? }
    end

    def extract_deposits_from_html
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
      ).any?
    end
  end
end
