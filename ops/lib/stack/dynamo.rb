module Stax
  class Dynamo < Stack
    no_commands do
      def cfn_parameters
        {
          app:      app_name,
          branch:   branch_name,
        }
      end
    end
  end
end
