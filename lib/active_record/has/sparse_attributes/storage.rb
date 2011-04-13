module ActiveRecord #:nodoc:
	module Has #:nodoc:
		module SparseAttributes #:nodoc:
			class StorageConfig
				
				attr_accessor :model_class
				attr_accessor :serialize_values
				
				def initialize(klass, options = {})
					@model_class = klass
					@serialize_values = options[:serialize] || false
				end

			end

			class Storage
				
				attr_accessor :config
				attr_accessor :record
				
				def initialize(record, config)
					@record = record
					@config = config
				end
				
				def get(name)
				end
				
				def set(name, value)
				end
				
				def before_save(*args)
				end
			
				def before_update(*args)
				end
				
				def after_save(*args)
				end
			end
		end
	end
end
