Gem::Specification.new do |s|
	s.name = %q{has_sparse_attributes}
	s.version = "1.1.0"

	s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
	s.authors = ["Edward Potocko"]
	s.date = %q{2016-10-18}
	s.email = %q{epotocko@equallevel.com}
	s.summary = "Extension for ActiveRecord to allow sparse attributes"
	s.files = [
		 "init.rb",
		 "lib/has_sparse_attributes.rb",
		 "lib/active_record/has/sparse_attributes.rb",
		 "lib/active_record/has/sparse_attributes/column_storage.rb",
		 "lib/active_record/has/sparse_attributes/storage.rb",
		 "lib/active_record/has/sparse_attributes/table_storage.rb",
	]
	s.rdoc_options = ["--charset=UTF-8"]
	s.require_paths = ["lib"]

	if s.respond_to? :specification_version then
		current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
		s.specification_version = 3
	end
end
