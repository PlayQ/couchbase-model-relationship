require 'active_support/concern'
require 'active_support/core_ext/hash/indifferent_access'
require 'active_support/core_ext/string/inflections'
require 'active_support/core_ext/object/try'

require 'active_model'

require "couchbase/model/relationship/version"
require 'couchbase/model'
require 'couchbase/model/deep_copier'
require 'couchbase/model/attributes'
require 'couchbase/model/dirty'
require 'couchbase/model/id_prefix'
require 'couchbase/model/relationship/association'
require 'couchbase/model/relationship/parent'
require 'couchbase/model/relationship/child'

module Couchbase
  class Model
    module Relationship
    end
  end
end

# Setup code

Couchbase::Model.send :include, Couchbase::Model::Attributes
Couchbase::Model.send :include, Couchbase::Model::Dirty
Couchbase::Model.send :include, Couchbase::Model::IdPrefix
Couchbase::Model.send :include, Couchbase::Model::Relationship::Parent
Couchbase::Model.send :include, Couchbase::Model::Relationship::Child

