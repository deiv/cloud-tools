
Region      = Struct.new(:name, :ami)
Instance    = Struct.new(:name, :type, :price)
Nodes       = Struct.new(:instance, :count, :slots, :securitygroups)
BuildSet    = Struct.new(:name, :nodes, :tasks)
Credentials = Struct.new(:name, :id, :secret)
