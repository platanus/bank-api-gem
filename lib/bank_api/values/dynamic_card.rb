require 'yaml'

class DynamicCard
  def initialize(entries)
    @coordinates_array = YAML::load(entries.gsub(/,\s*([^\s])/, ', \1'))
  end

  def get_coordinate_value(coordinate)
    col = ('A'..'J').to_a.index(coordinate[0])
    row = (1..5).to_a.index(coordinate[1].to_i)
    @coordinates_array[row][col]
  end
end
