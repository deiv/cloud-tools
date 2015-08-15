
Region      = Struct.new(:name, :amis, :defaultami)
Instance    = Struct.new(:name, :type, :price, :ami)
Nodes       = Struct.new(:instance, :count, :slots, :securitygroups, :tags, :'vpc-subnet-id', :'vpc-securitygroups-ids', :ami)
BuildSet    = Struct.new(:name, :nodes, :tasks)
Credentials = Struct.new(:name, :id, :secret)
