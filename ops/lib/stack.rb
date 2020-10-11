## Monkey-patches you may make to change stack behavior.
## Changing these here will affect all stacks.
## You may also define these per-stack in the sub-class for each stack in lib/stacks/.

module Stax
  class Stack < Base

    no_commands do

      def ssm_environment
        @_ssm_environment ||= (Git.branch == 'master') ? 'production' : 'dev'
      end

    end

  end

end
