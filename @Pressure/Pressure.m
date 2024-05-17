classdef Pressure

    properties
    
        mesh_class;
        inlet_func;
        vent_func;
        p_D;

        %% FEM system of equations
        stiffness_matrix;
        load_vector;

        %% FEM solution of pressure problem
        pressure;
        pressure_gradient;

        %% inlet, outlet, and Nuemann boundary node lists
        inlet_nodes;
        outlet_nodes;
        Neumann_nodes;
        free_nodes;

        %% Legacy code
        bndry_nodes;
        nb_nodes;

        inlet_flag;
        inlet_pos;
        Dirichlet;
        vent_flag;
        vent_idx;
        Neumann_flag;

    end % end properties

    methods

        function obj = Pressure(mesh_class,inlet_func,vent_func,p_D)

            obj.mesh_class = mesh_class;
            obj.inlet_func = inlet_func;
            obj.vent_func = vent_func;
            obj.p_D = p_D;

            num_dofs = mesh_class.num_nodes;
            obj.pressure = obj.p_D(mesh_class.nodes,[],[],[]);
            obj.pressure_gradient = zeros(mesh_class.num_elements,2);

            %% Allocating FEM system of equations
            obj.stiffness_matrix = spalloc(num_dofs,num_dofs,10*num_dofs);
            obj.load_vector = zeros(num_dofs,1);

            [obj.inlet_flag, obj.inlet_pos, obj.Dirichlet] ...
                    = inlet_location(obj.mesh_class.nodes, obj.mesh_class.boundary_nodes);
            [obj.vent_flag] ...
                    = vent_location(obj.mesh_class.nodes, obj.mesh_class.boundary_nodes);
            obj.vent_idx = find(obj.vent_flag);

            %% Nuemann boundary condition
            obj.Neumann_flag = find_nuemann_points(obj.mesh_class.boundary_nodes,obj.inlet_flag, obj.vent_flag);

        end



    end % end methods

end

function obj = compute_inlets_outlets(obj)

%% Extract needed mesh information
nodes = obj.mesh_class.nodes;
num_nodes = obj.mesh_class.num_nodes;
boundary_nodes = obj.mesh_class.boundary_nodes;

%% Legacy code inlet/vent flags
obj.inlet_flag = false(num_nodes,1);
obj.vent_flag = false(num_nodes,1);

for node_index = boundary_nodes

    boundary_point = nodes(node_index,:);

    obj.inlet_flag(node_index) = is_inlet(boundary_point);
    obj.vent_flag(node_index) = is_vent(boundary_point);
    
    



end

end

function neumann_flag = find_nuemann_points(bnd_nodes,inlet_flag, vent_flag)

%% just set as the set difference of a boundary list, the inlets and outlets
nnode = length(bnd_nodes);
nbnd_node = nnz(bnd_nodes);
candidate = find(bnd_nodes);
neumann_flag = zeros(nnode,1);
for i = 1 : nbnd_node
    ci = candidate(i);
    if ~inlet_flag(ci)&& ~vent_flag(ci)
        neumann_flag(ci) = 1;
    end
end
neumann_flag = sparse(neumann_flag);

end