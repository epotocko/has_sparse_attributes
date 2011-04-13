$:.unshift "#{File.dirname(__FILE__)}/lib"
require 'active_record/has/sparse_attributes'
ActiveRecord::Base.class_eval { include ActiveRecord::Has::SparseAttributes }
