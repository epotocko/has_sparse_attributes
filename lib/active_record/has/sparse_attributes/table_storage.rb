module ActiveRecord #:nodoc:
	module Has #:nodoc:
		module SparseAttributes #:nodoc:
			
			class TableStorageConfig < StorageConfig
				attr_accessor :attribute_model
				attr_accessor :id_column
				
				def initialize(klass, options = {})
					super
					options[:attribute_class_name] ||= 'SparseAttribute'
					options[:id_column] ||= @model_class.model_name.singular.to_s + '_id'
					if !options[:table_name].blank?
						table_name = ('set_table_name "' + options[:table_name] + '";') || ''
					else
						table_name = ''						
					end
					@id_column = options[:id_column]
					klass.class_eval "class #{options[:attribute_class_name]} < ActiveRecord::Base; #{table_name} validates_presence_of :#{@id_column}, :name; end"
					@attribute_model = eval("klass::#{options[:attribute_class_name]}")
				end
				
				def instance(record)
					TableStorage.new(record, self)
				end
			end
			
			class TableStorage < Storage
				attr_accessor :sparse_attributes
				attr_accessor :sparse_attribute_values
				attr_accessor :updated_sparse_attributes
				
				def after_save(*args)
					save()
				end

				def load()
					@sparse_attributes = {}
					@sparse_attribute_values = {}
					@updated_sparse_attributes = []
					
					# The item has not been saved - nothing to load
					if @record.id.nil?
						return
					end
					
					unserialize = @config.serialize_values
					attributes = @config.attribute_model.find(:all, :conditions => { @config.id_column => @record.id })
					attributes.each do |attr|
						@sparse_attributes[attr.name] = attr
						@sparse_attribute_values[attr.name] = unserialize ? YAML::load(attr.value) : attr.value
					end
				end
				
				def save()
					return 0 if @updated_sparse_attributes.nil?
					num_updates = 0
					klass = @config.attribute_model
					klass_id_column = @config.id_column
					serialize = @config.serialize_values
					@updated_sparse_attributes.each do |name|
						value = @sparse_attribute_values[name]
						have_attribute = @sparse_attributes.has_key?(name)
						
						# If the value is nil we will delete the attribute row
						if value.nil?
							num_updates += delete_row(name)
						else
							value = value.to_yaml if serialize
							num_updates += 1 if set_row(name, value)
						end
					end
				
					@updated_sparse_attributes = []
					return num_updates
				end
				
				def get(name)
					load() if @sparse_attributes.nil?
					return @sparse_attribute_values[name.to_s]
				end
				
				def set(name, value)
					load() if @sparse_attributes.nil?

					name = name.to_s
					if value.nil?
						@sparse_attribute_values[name] = nil
					else
						value = value.to_s unless @config.serialize_values
						@sparse_attribute_values[name] = value
					end
					@updated_sparse_attributes << name
				end
				
			protected
			
				def delete_row(name)
					klass = @config.attribute_model
					have_attribute = @sparse_attributes.has_key?(name)
							
					# If we have the attribute ActiveRecord instance
					# we may be able to just delete the row
					deleted = klass.delete(@sparse_attributes[name].id) if have_attribute

					# If the attribute couldn't be deleted by id 
					# we just scan for the record
					if !have_attribute || deleted == 0
						deleted = klass.delete_all(["#{@config.id_column} = ? AND name = ?", @record.id, name])
					end
					return deleted
				end
				
				def set_row(name, value)
					klass = @config.attribute_model
					klass_id_column = @config.id_column
					have_attribute = @sparse_attributes.has_key?(name)

					if have_attribute					
						# We already have the attribute so we should be able to just update
						# the row based on the id, unless it has been deleted
						attribute = @sparse_attributes[name]
						attribute.value = value
						updated = attribute.save
					end
						
					if !have_attribute || updated == false
						# TODO: fix synchronization issues
						method_name = ('find_or_create_by_' + klass_id_column.to_s + '_and_name').to_sym
						attribute = klass.send(method_name, klass_id_column => @record.id, :name => name, :value => value)
						if !attribute.new_record?
							attribute.value = value
							updated = attribute.save
						else
							updated = 1
						end
						@sparse_attributes[name] = attribute
					end
					return updated
				end
				
			end
		end
	end
end
