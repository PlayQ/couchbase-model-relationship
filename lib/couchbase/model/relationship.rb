require 'active_support/concern'
require 'active_support/core_ext/hash/indifferent_access'

require 'active_model'

require "couchbase/model/relationship/version"
require 'couchbase/model'
require 'couchbase/model/attributes'
require 'couchbase/model/dirty'

module Couchbase
  class Model
    module Relationship
    end
  end
end

# Setup code

Couchbase::Model.send :include, Couchbase::Model::Attributes
Couchbase::Model.send :include, Couchbase::Model::Dirty
