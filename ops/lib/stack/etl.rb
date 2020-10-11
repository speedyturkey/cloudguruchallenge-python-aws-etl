module Stax
  class Etl < Stack
    no_commands do
      def cfn_parameters
        super.merge(
          app:      app_name,
          branch:   branch_name,
        )
      end
    end
  end
end
