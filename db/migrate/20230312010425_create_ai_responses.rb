class CreateAiResponses < ActiveRecord::Migration[7.0]
  def change
    create_table :ai_responses do |t|

      t.text :response
      t.string :stock

      t.timestamps
    end
  end
end
