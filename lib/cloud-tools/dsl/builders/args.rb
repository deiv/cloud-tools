
require 'cloud-tools/dsl/dsl_syntax'

module Dsl; module Builders;

  class ArgsBuilder
    include DslSyntax

    attr_reader :model

    def initialize
      @model = {}
    end

    def no_arch_all
      @model[:no_arch_all] = true
    end

    def mode(m)
      @model[:modes] = @model[:modes] || []
      @model[:modes] << m if not @model[:modes].include? m
    end

    def time_lower(t)
      @model[:time_lower] = t
    end

    def time_upper(t)
      @model[:time_upper] = t
    end

    def chroot(c)
      @model[:chroot] = c
    end

    def log_id(id)
      @model[:log_id] = id
    end

    def include_pkgs(f)
      @model[:include_pkgs] = f
    end

    def exclude_pkgs(f)
      @model[:exclude_pkgs] = f
    end
  end

end; end;

