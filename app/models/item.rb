class Item < ActiveRecord::Base
  attr_accessible :attributes, :description, :name, :url
end
