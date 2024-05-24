classdef Visualisation

    properties

        %% booleans to decide what to plot
        is_plotting_pressure;
        is_plotting_velocity;
        is_plotting_volume_flow;
        is_plotting_volume;

        %% booleans to decide what to annimate
        is_animate_pressure;
        is_annimate_velocity;
        is_annimate_volume_flow;
        is_annimate_volume;

    end % end properties

    methods

        function obj = Visualisation()
            
            %% default is only plot the volume
            obj.is_plotting_pressure = false;
            obj.is_plotting_velocity = false;
            obj.is_plotting_volume_flow = false;
            obj.is_plotting_volume = true;
    
            %% no animations by default (heavy on cpu)
            obj.is_animate_pressure = false;
            obj.is_annimate_velocity = false;
            obj.is_annimate_volume_flow = false;
            obj.is_annimate_volume = false;

        end

        function plot(obj,cvfem_class) 

            figure(1)
            clf;
            fluid_elements = cvfem_class.active_elements;
            fluid_elements(fluid_elements>0) = 1;

            pdeplot(cvfem_class.mesh_class.nodes',...
                    cvfem_class.mesh_class.elements', ...
                    XYData=fluid_elements,ColorMap="jet",Mesh="on")
            axis equal
            title(["plot of fluid position at time = " ...
                                                num2str(cvfem_class.time)])

        end

        function annimate(obj,cvfem_class)

            


        end

    end
end