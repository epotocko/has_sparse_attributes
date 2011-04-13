require 'active_record/has/sparse_attributes/storage'
require 'active_record/has/sparse_attributes/column_storage'
require 'active_record/has/sparse_attributes/table_storage'

module ActiveRecord #:nodoc:
	module Has #:nodoc:
		module SparseAttributes #:nodoc:
			def self.included(base) #:nodoc:
				base.extend(ClassMethods)
			end
			
			module ClassMethods #:nodoc:
				
				def has_sparse_attributes(attribute_names, *options)
					options = options.extract_options!
					options[:storage] ||= :column
					options[:serialize] ||= false
					storage = options[:storage].to_sym
					
					# First-time initialization
					if not self.methods.include?('sparse_attributes')
						class_eval <<-EOV
							cattr_accessor :sparse_attributes, :instance_writer => false
							@@sparse_attributes = {}

							cattr_accessor :sparse_attribute_storage_configs
							@@sparse_attribute_storage_configs = []
							
							before_update :sparse_attributes_before_update
							before_save :sparse_attributes_before_save
							after_save :sparse_attributes_after_save

							def self.has_sparse_attribute?(name)
								attribute = name.to_s
								attribute = attribute[0..-2] if attribute.ends_with?('=')
								return self.sparse_attributes.has_key?(attribute.to_sym)
							end
	
							include ActiveRecord::Has::SparseAttributes::InstanceMethods
						EOV
					end
					
					# Add getters and setters for each sparse attribute
					attribute_names.each do |name|
						class_eval <<-EOV
							def #{name}()
								get_sparse_attribute(:#{name})
							end
						
							def #{name}=(v)
								set_sparse_attribute(:#{name}, v)
							end
						EOV
					end
					
					if storage == :column
						storage_config = ColumnStorageConfig.new(self, options)
					elsif storage == :table
						storage_config = TableStorageConfig.new(self, options)
					else
						raise StandardError.new("Invalid storage option for has_sparse_attributes")
					end
					
					self.sparse_attribute_storage_configs << storage_config
					storage_id = self.sparse_attribute_storage_configs.length - 1

					attribute_names.each do |name|
						self.sparse_attributes[name.to_sym] = storage_id
					end

				end
			end

			module InstanceMethods

				def get_sparse_attribute(name)
					self.get_sparse_attribute_storage(name).get(name)
				end
				
				def set_sparse_attribute(name, value)
					self.get_sparse_attribute_storage(name).set(name, value)
				end

			protected
				
				attr_accessor :sparse_attribute_storage
				
				def get_sparse_attribute_storage(name)
					create_sparse_attribute_storage()
					self.sparse_attribute_storage[self.class.sparse_attributes[name.to_sym]]
				end
				
				def create_sparse_attribute_storage()
					if self.sparse_attribute_storage.nil?
						self.sparse_attribute_storage = []
						self.class.sparse_attribute_storage_configs.each do |config|
							self.sparse_attribute_storage << config.instance(self)
						end
					end
				end
				
				def sparse_attributes_before_update(*args)
					create_sparse_attribute_storage()
					self.sparse_attribute_storage.each do |store|
						store.before_update(*args)
					end
				end
				
				def sparse_attributes_before_save(*args)
					create_sparse_attribute_storage()
					self.sparse_attribute_storage.each do |store|
						store.before_save(*args)
					end
				end
				
				def sparse_attributes_after_save(*args)
					create_sparse_attribute_storage()
					self.sparse_attribute_storage.each do |store|
						store.after_save(*args)
					end
				end

			end
		end
	end
end
