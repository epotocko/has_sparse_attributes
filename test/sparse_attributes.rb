$: << (File.expand_path(File.dirname(__FILE__) + "/../lib"))

DATABASE_TYPE = :sqlite3

require 'rubygems'

gem 'activerecord', '4.0.13'
require 'active_record'

gem 'minitest'
require 'minitest/autorun'

if defined?(MiniTest::Test)
	TestCase = MiniTest::Test
elsif defined?(MiniTest::Unit::TestCase)
	TestCase = MiniTest::Unit::TestCase
elsif defined?(Test::Unit::TestCase)
	TestCase = Test::Unit::TestCase
end

require_relative "../init"

if DATABASE_TYPE == :sqlite3
	ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")
elsif DATABASE_TYPE == :postgresql
	ActiveRecord::Base.establish_connection(
	  :host => 'db1',
	  :adapter => 'postgresql',
	  :encoding => 'utf8',
	  :database => 'rails_plugin_test',
	  :pool => 5,
	  :username => 'rails_test',
	  :password => 'test123'
	)
end

def setup_db
	ActiveRecord::Schema.define(:version => 1) do
		create_table :electric_guitars do |t|
			t.string :brand, :limit => 255
			t.string :model, :limit => 255
			t.integer :strings, :default => 6
			t.text :sparse_attributes
			t.column :created_at, :datetime      
			t.column :updated_at, :datetime
		end
		
		create_table :electric_basses do |t|
			t.string :brand, :limit => 255
			t.string :model, :limit => 255
			t.integer :strings, :default => 4
			t.column :created_at, :datetime      
			t.column :updated_at, :datetime
		end
		
		create_table :electric_bass_sparse_attributes do |t|
			t.references :electric_bass
			t.string :name, :limit => 255
			t.string :value, :limit => 1024
		end

		add_index :electric_bass_sparse_attributes, [:electric_bass_id, :name], :name => 'uniq_electric_bass_sparse_attributes', :unique => true

		create_table :acoustic_guitars do |t|
			t.string :brand, :limit => 255
			t.string :model, :limit => 255
			t.integer :strings, :default => 6
			t.text :sparse_attributes
			t.column :created_at, :datetime      
			t.column :updated_at, :datetime
		end
		
		create_table :acoustic_basses do |t|
			t.string :brand, :limit => 255
			t.string :model, :limit => 255
			t.integer :strings, :default => 4
			t.column :created_at, :datetime      
			t.column :updated_at, :datetime
		end
		
		create_table :acoustic_bass_sparse_attributes do |t|
			t.references :acoustic_bass
			t.string :name, :limit => 255
			t.string :value, :limit => 1024
		end

		add_index :acoustic_bass_sparse_attributes, [:acoustic_bass_id, :name], :name => 'uniq_acoustic_bass_sparse_attributes', :unique => true

		create_table :acoustic_guitar_cases do |t|
			t.references :acoustic_guitar
		end

	end
end

def teardown_db
	ActiveRecord::Base.connection.tables.each do |table|
		ActiveRecord::Base.connection.drop_table(table)
	end
end

class ElectricGuitar < ActiveRecord::Base
	has_sparse_attributes([:weight, :color, :year], :storage => :column)
end

class ElectricBass < ActiveRecord::Base
	has_sparse_attributes([:weight, :color, :year], :storage => :table)
end

class AcousticGuitar < ActiveRecord::Base
	has_sparse_attributes([:weight, :color, :year], :storage => :column, :serialize => true)
end

class AcousticBass < ActiveRecord::Base
	has_sparse_attributes([:weight, :color, :year], :storage => :table, :serialize => true)
end

class AcousticGuitarCase < ActiveRecord::Base
	belongs_to :acoustic_guitar
end


class SparseAttributesTest < TestCase
	
	def setup
		setup_db
	end
	
	def teardown
		teardown_db
	end
	
	def test_column
		basic_test(ElectricGuitar, false)
	end

	def test_table
		basic_test(ElectricBass, false)
	end

	def test_column_serialized
		basic_test(AcousticGuitar, true)
	end

	def test_table_serialized
		basic_test(AcousticBass, true)
	end

	def test_column_merge
		merge_test(ElectricGuitar)
		merge_test(AcousticGuitar)
	end
	
	def test_table_merge
		merge_test(ElectricBass)
		merge_test(AcousticBass)
	end
	
	def test_column_serialized_has_one
		has_one_test(AcousticGuitar, AcousticGuitarCase)
	end

	def basic_test(klass, serialized)
		x = klass.new()
		brand = x.brand = 'Fender'
		model = x.model = 'Stratocaster'
		color = x.color = 'Green'
		weight = x.weight = 50
		
		assert_equal brand, x.brand
		assert_equal model, x.model
		assert_equal color, x.color
		assert_equal weight.to_s, x.weight if !serialized
		assert_equal weight, x.weight if serialized
		assert_equal nil, x.year
		x.save!

		y = klass.find(x.id)
		assert_equal y.id, x.id
		assert_equal x.brand, y.brand
		assert_equal x.model, y.model
		assert_equal x.color, y.color
		assert_equal x.weight, y.weight.to_s if !serialized	
		assert_equal x.weight, y.weight if serialized
		assert_equal y.year, nil
		
		brand = y.brand = "Washburn"
		year = y.year = 1999
		assert_equal brand, y.brand
		assert_equal year.to_s, y.year if !serialized
		assert_equal year, y.year if serialized
		y.color = nil
		assert_equal nil, y.color
		
		y.save
		assert_equal year.to_s, y.year if !serialized
		assert_equal year, y.year if serialized
		assert_equal nil, y.color
		
		z = klass.find(y.id)
		assert_equal year.to_s, z.year if !serialized
		assert_equal year, z.year if serialized
		assert_equal nil, z.color
		
		z.color = 'green'
		z.year = 1999
		z.weight = ['test']
		z.save
		
		xid = x.id
		x = klass.find(xid)
		assert_equal x.id, xid
		assert_equal z.color, x.color

		assert_equal true, klass.has_sparse_attribute?(:weight)
		assert_equal true, klass.has_sparse_attribute?('color')
		assert_equal false, klass.has_sparse_attribute?(:fake)
		assert_equal false, klass.has_sparse_attribute?('achua')
		
		x = klass.first
		x.set_sparse_attribute(:color, 'aqua')
		x.save
		
		x = klass.find(x.id)
		assert_equal 'aqua', x.get_sparse_attribute(:color)
		assert_equal 'aqua', x.color
		
		x = klass.first
		x.set_sparse_attribute('color', 'blue')
		x.save
		
		x = klass.find(x.id)
		assert_equal 'blue', x.get_sparse_attribute('color')
		assert_equal 'blue', x.color
		
		a = klass.new()
		a.color = 'green'
		a.save!
		aid = a.id
		assert_equal a.color, 'green'
		a.color = 'blue'
		assert_equal a.color, 'blue'
		a.save!
		assert_equal a.color, 'blue'
		
		a = klass.find(aid)
		assert_equal a.color, 'blue'
		a.color = 'yellow'
		assert_equal a.color, 'yellow'
		a.save!
		assert_equal a.color, 'yellow'
		
		a = klass.find(aid)
		assert_equal a.color, 'yellow'
	end
	
	def merge_test(klass)
		x = klass.new()
		brand = x.brand = 'Fender'
		model = x.model = 'Stratocaster'
		color = x.color = 'Green'
		weight = x.weight = 5
		x.save!
		
		y = klass.find(x.id)
		z = klass.find(x.id)
		
		y.weight = "6"
		z.weight = "7"
		y.color = "Blue"
		z.year = "2000"
		
		y.save!
		z.save!
		
		x = klass.find(y.id)
		
		assert_equal z.weight, x.weight
		assert_equal y.color, x.color
		assert_equal z.year, x.year
		
	end
	
	def has_one_test(klass, caseKlass)
		x1 = klass.new
		x1.brand = 'test'
		x1.model = 'test'
		x1.color = 'green'
		x1.save
		c1 = caseKlass.new
		c1.acoustic_guitar = x1
		c1.save
		
		c2 = caseKlass.find(c1.id)
		x2 = klass.find(x1.id)

		assert_equal c1.id, c2.id
		assert_equal c1.acoustic_guitar.brand, x2.brand

	end

end
