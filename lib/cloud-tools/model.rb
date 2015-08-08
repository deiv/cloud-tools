
Region      = Struct.new(:name, :ami)
Instance    = Struct.new(:name, :type, :price)
Nodes       = Struct.new(:instance, :count, :slots, :securitygroups, :tags, :'vpc-subnet-id', :'vpc-securitygroups-ids')
BuildSet    = Struct.new(:name, :nodes, :tasks)
Credentials = Struct.new(:name, :id, :secret)
