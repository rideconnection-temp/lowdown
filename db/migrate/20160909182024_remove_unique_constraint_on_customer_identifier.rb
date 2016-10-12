class RemoveUniqueConstraintOnCustomerIdentifier < ActiveRecord::Migration
  def change
    remove_index :customers, :identifier
  end
end
