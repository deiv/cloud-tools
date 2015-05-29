
require 'spec_helper'

require 'cloud-tools/dsl/model'

describe ::Dsl::Model::BalancedNodes do

  before do
    @uppertask = 1
    @lowertask = 2
    @dsl_syntax_mock = ::Dsl::Model::BalancedNodes.new(1600, @uppertask, @lowertask)
  end

  describe "when 'each_tasks' method is called" do

    it "should yield the tasks in the correct order" do
      tasks = []
      @dsl_syntax_mock.each_tasks do |task|
        tasks << task
      end

      assert_equal tasks.length, 2
      assert_equal tasks[0], @uppertask
      assert_equal tasks[1], @lowertask
    end
  end
end
