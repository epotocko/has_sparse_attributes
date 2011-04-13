module ActiveRecord #:nodoc:
	module Has #:nodoc:
		module SparseAttributes #:nodoc:
			
			class ColumnStorageConfig < StorageConfig
				attr_accessor :column_name
				
				def initialize(klass, options = {})
					super
					@column_name = options[:column_name] || 'sparse_attributes'
					@model_class.class_eval "serialize '#{@column_name}'"
				end
				
				def instance(record)
					ColumnStorage.new(record, self)
				end
			end
			
			class ColumnStorage < Storage
				attr_accessor :updated_attributes

				def get(name)
					col = @config.column_name
					return nil if @record[col].nil?
					return @record[col][name.to_s]
				end
				
				def set(name, value)
					name = name.to_s
					col = @config.column_name
					@updated_attributes = {} if @updated_attributes.nil?
					if @record[col].nil?
						@record[col] = {}
					end
					a = @record[col]
					if value.nil?
						a.delete(name)
					else
						value = value.to_s if !@config.serialize_values
						a[name] = value
					end
					@updated_attributes[name] = true
					@record[col] = a
				end
				
				def before_update(*args)
					merge_sparse_attributes()
				end
				
				def after_save(*args)
					clear_updated_sparse_attributes()
				end
				
			protected
				
				def merge_sparse_attributes()
					return if @updated_attributes.nil?
					col = @config.column_name
					obj = @config.model_class.find(@record.id, { :select => col.to_s })
					current = obj[col]
					if current.nil? or current.empty?
						return
					end
					@updated_attributes.each do |key, value|
						if @record[col].has_key?(key)
							current[key] = @record[col][key]
						else
							current.delete(key)
						end
					end
					@record[col] = current
				end
				
				def clear_updated_sparse_attributes
					@updated_attributes = {}
				end
			end
		end
	end
end
