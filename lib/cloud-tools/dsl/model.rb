
module Dsl; module Model;

  DslBuildSet = Struct.new(:name, :nodes, :args)

  BalancedNodes = Struct.new(:midpoint, :uppertask, :lowertask) do
    def each_tasks
      yield uppertask
      yield lowertask
    end
  end

end; end;
