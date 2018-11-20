module Utils
  module BancoDeChile
    extend self

    def unpad_zeroes(string)
      /0*(.*)/.match(string).captures.first
    end

    def format_rut(rut)
      rut_ = unpad_zeroes(rut)
      verification_digit = rut_[-1]
      without_verification_digit = rut_[0..-2].reverse.scan(/.{1,3}/).join(".").reverse
      "#{without_verification_digit}-#{verification_digit}"
    end
  end
end
