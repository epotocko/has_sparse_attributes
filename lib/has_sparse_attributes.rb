require 'active_record/has/sparse_attributes'
ActiveRecord::Base.class_eval { include ActiveRecord::Has::SparseAttributes }