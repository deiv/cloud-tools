
require 'spec_helper'

require 'cloud-tools/dsl/exceptions'
require 'cloud-tools/dsl/builders/args'

dsl_full = <<EOT
  no_arch_all
  mode :binary_only
  log_id 'normal'
EOT

dsl_modes = <<EOT
  mode :binary_only
  mode 'normal'
EOT

dsl_bad = <<EOT
  mode :binary_only
  node 'normal'
EOT

supported_params = {
  "no_arch_all" => true,
  "mode" => "normal",
  "time_lower" => "100",
  "time_upper" => "300",
  "chroot" => "unstable",
  "log_id" => "/some/path/log",
  "include_pkgs" => "/some/path/include",
  "exclude_pkgs" => "/some/path/exclude"
}

describe ::Dsl::Builders::ArgsBuilder do

  before do
    @args_builder = ::Dsl::Builders::ArgsBuilder.new
  end

  describe "when a valid block is evaluated" do

    it "should return a hash" do
      @args_builder.eval_block { eval dsl_full }
      assert_equal Hash, @args_builder.model.class
    end

    it "should generate the correct model" do
      @args_builder.eval_block { eval dsl_full }
      assert_equal 3, @args_builder.model.size
      assert_equal true, @args_builder.model[:no_arch_all]
      assert_equal 1, @args_builder.model[:modes].size
      assert_equal :binary_only, @args_builder.model[:modes][0]
      assert_equal 'normal', @args_builder.model[:log_id]
    end


    supported_params.each do |k, v|
      it "should suport the parameter '#{k}' syntax" do
        dsl_param = "#{k}"
        dsl_param += " '#{v}'" if not v.is_a? TrueClass

        begin
          @args_builder.eval_block { eval dsl_param }

          if k == "mode"
            assert_equal [v], @args_builder.model[:modes]
          else
            assert_equal v, @args_builder.model[k.to_sym]
          end

        rescue ::Dsl::InvalidSyntaxError
          assert false, "Dsl::InvalidSyntaxError raised"
        end
      end
    end
  end

  describe "when no block is evaluated" do

    it "should return an empty hash" do
      assert_equal Hash, @args_builder.model.class
      assert_equal 0, @args_builder.model.size
    end
  end

  describe "when a block with multiple modes is evaluated" do

    it "should not overwrite them" do
      @args_builder.eval_block { eval dsl_modes }
      assert_equal [:binary_only, 'normal'], @args_builder.model[:modes]
      assert_equal 2, @args_builder.model[:modes].size
    end

    it "should merge duplicates" do
      @args_builder.eval_block { eval "#{dsl_modes}\n#{dsl_modes}" }
      assert_equal [:binary_only, 'normal'], @args_builder.model[:modes]
      assert_equal 2, @args_builder.model[:modes].size
    end
  end

  describe "when a invalid block is evaluated" do

    it "should raise an InvalidSyntaxError exception" do
      assert_raises ::Dsl::InvalidSyntaxError do
        @args_builder.eval_block { eval dsl_bad }
      end
    end
  end
end
