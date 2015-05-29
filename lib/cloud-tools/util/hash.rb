
class Hash

  def deep_copy
    # make a deep copy
    Marshal.load(Marshal.dump(self))
  end

  def merge_deep_copy(other_hash)
    #deep_copy  #return self if not other_hash
    
    merged = self.merge other_hash do |key, old, new|
      if old.is_a? Array or new.is_a? Array
        old + new
      else
        new
      end
    end

    merged.deep_copy
  end

  def merge_adding_arys(other_hash)
    return self if not other_hash

    self.merge other_hash do |key, old, new|
      if old.is_a? Array or new.is_a? Array
        old + new
      else
        new
      end
    end
  end

  def merge_adding_arys!(other_hash)
    return self if not other_hash
    
    self.merge! other_hash do |key, old, new|
      if old.is_a? Array or new.is_a? Array
        old + new
      else
        new
      end
    end
  end
end
