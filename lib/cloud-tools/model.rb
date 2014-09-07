
Region      = Struct.new(:name, :ami)
Instance    = Struct.new(:name, :type, :price)
Nodes       = Struct.new(:instance, :count, :slots)
BuildTask   = Struct.new(:name, :nodes, :args)
BalancedSet = Struct.new(:name, :midpoint, :uppertask, :lowertask)
MixedSet    = Struct.new(:name, :nodes, :tasks)
Credentials = Struct.new(:name, :id, :secret)
