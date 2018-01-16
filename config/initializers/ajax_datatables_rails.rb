AjaxDatatablesRails.configure do |config|
  # available options for db_adapter are: :pg, :mysql2, :sqlite3
    config.db_adapter = :mysql2
end

module AjaxDatatablesRails
  class Base
    def search_condition(column, value)
      model, column = column.split('.')
      model = model.singularize.titleize.gsub( / /, '' ).constantize
      str = Arel::Nodes::SqlLiteral.new("'%#{value.downcase}%'")
      model.arel_table[column.to_sym].lower.matches(str)
    end
  end
end
