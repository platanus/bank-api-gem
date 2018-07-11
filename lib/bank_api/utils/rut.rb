module Utils
  module Rut
    extend self

    def strip_rut(rut)
      rut.tr(".-", "")
    end
  end
end
