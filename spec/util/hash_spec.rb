
require 'spec_helper'

require 'cloud-tools/dsl/cooker'

# XXX

describe Hash do

  describe "" do

    it "should merge adding arys correctly" do
      first_hash = { :key1 => 'val1', :key1_2 => ['val1_2'] }
      second_hash = { :key2 => 'val2', :key1_2 => ['val2_2', 'val2_3']}
      result_hash = { :key1 => 'val1', :key1_2=>['val1_2', 'val2_2', 'val2_3'], :key2 => 'val2'}

      merged_args = first_hash.merge_adding_arys second_hash
      assert_equal result_hash, merged_args

      refute_equal first_hash, merged_args

      first_hash.merge_adding_arys! second_hash
      assert_equal result_hash, first_hash
    end

    it "should do a deep copy correctly" do
      first_hash = { :key1 => 'val1', :key1_2 => {:key_changed => 'initial'} }
      second_hash = { :key2 => 'val2' }
      result_hash = first_hash.merge(second_hash)

      merged_args = first_hash.merge_deep_copy second_hash

      first_hash[:key1_2][:key_changed] = 'key_changed'

      refute_equal result_hash, merged_args
    end
  end
end
