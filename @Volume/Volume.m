classdef Volume

    properties
    
        mesh_class;
        darcy_class;

        %% Measure of control volumes in 3D (using thickness approximation)
        volume_measures;

        %% Control volume outward facing normals (scaled by edge length)
        volume_outflow_vectors;

        %% inlet, outlet, and Nuemann boundary node lists
        inlet_nodes;
        outlet_nodes;

        %% connectivity features of the Volume elements
        node_connectivity;
        element_connectivity;

        %% legacy code
        has_node_i;
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
        %% Methods of the Volume class

        function obj = Volume(pressure_class,darcy_class)

            obj.mesh_class = pressure_class.mesh_class;
            obj.darcy_class = darcy_class;

            obj = obj.compute_volume_measures();
            obj = obj.compute_volume_outflow_vectors();
            obj = obj.compute_connectivity();

            inlet_location = pressure_class.inlet_func;
            vent_location = pressure_class.vent_func;

            [obj.inlet_flag, obj.inlet_pos, obj.Dirichlet] ...
                    = inlet_location(obj.mesh_class.nodes, obj.mesh_class.boundary_nodes);
            [obj.vent_flag] ...
                    = vent_location(obj.mesh_class.nodes, obj.mesh_class.boundary_nodes);
            obj.vent_idx = find(obj.vent_flag);

            %% Nuemann boundary condition
            obj.Neumann_flag = find_nuemann_points(opt.mesh.bndry_nodes,obj.inlet_flag, obj.vent_flag);

        end

        function obj = compute_volume_measures(obj)
            
            obj.volume_measures = zeros(obj.mesh_class.num_nodes,1);

            for i = 1:obj.mesh_class.num_elements
                
                element_area = obj.mesh_class.element_areas(i);
                control_volumes = obj.mesh_class.elements(i,:);
                sub_volume_measures = element_area/3 * obj.darcy_class.thickness *ones(3,1);
                obj.volume_measures(control_volumes) = obj.volume_measures(control_volumes) + sub_volume_measures;
            end
        end

        function obj = compute_volume_outflow_vectors(obj)

            nodes = obj.mesh_class.nodes;
            elements = obj.mesh_class.elements;
            centroids = obj.mesh_class.centroids;

            %% compute midpoints on triangular elements
            a = (nodes(elements(:,1),:) + nodes(elements(:,2),:))/2;
            b = (nodes(elements(:,2),:) + nodes(elements(:,3),:))/2;
            c = (nodes(elements(:,3),:) + nodes(elements(:,1),:))/2;
            
            %% compute outward triangle element normals
            n1 = [centroids(:,2)-a(:,2) a(:,1)-centroids(:,1)];
            n2 = [centroids(:,2)-b(:,2) b(:,1)-centroids(:,1)];
            n3 = [centroids(:,2)-c(:,2) c(:,1)-centroids(:,1)];
            
            %% outlfow and inflow vectors for each control volume
            n31 = n3 - n1;
            n12 = n1 - n2;
            n23 = n2 - n3;

            %% outward flows for each control volume in this triangle
            obj.volume_outflow_vectors = [n31 n12 n23];

        end

        function obj = compute_connectivity(obj)

            %% Unpack the arguments
            elem = obj.mesh_class.elements;
            nnode = obj.mesh_class.num_nodes;
            
            %%
            nelem = size(elem,1);
            bndry_nodes = zeros(nnode,1);
            totalEdge = [elem(:,[2,3]); elem(:,[3,1]); elem(:,[1,2])];
            has_node_i = zeros(nnode,8);
            has_node_i_size = zeros(nnode,1);
            
            % Find elements containing the node i and store them in has_node_i
            for i = 1 : nelem
                e1 = elem(i,1);
                e2 = elem(i,2);
                e3 = elem(i,3);
            
                has_node_i_size(e1) = has_node_i_size(e1)+1;
                has_node_i(e1,has_node_i_size(e1)) = i;
                has_node_i_size(e2) = has_node_i_size(e2)+1;
                has_node_i(e2,has_node_i_size(e2)) = i;
                has_node_i_size(e3) = has_node_i_size(e3)+1;
                has_node_i(e3,has_node_i_size(e3)) = i;
            end
            has_node_i = [has_node_i_size has_node_i];
            
            % Cnode is a sparse matrix and nonzero entries represent the connectivity between two nodes. 
            % The matrix entries are the element that contains edge between two nodes. 
            Cnode = sparse(totalEdge(:,1),totalEdge(:,2),[1:nelem 1:nelem 1:nelem]',nnode,nnode);
            
            nb_nodes = cell(nnode,1);
            for i = 1 : nnode
                nb_nodes{i} = find(Cnode(:,i));
            end
            
            % Celem is a cennectivity matrix between elements. If two elements share an
            % edge then the corresponding values in Celem is an index of that edge.
            icelem = zeros(3*nelem,1);
            jcelem = zeros(3*nelem,1);
            kcelem = zeros(3*nelem,1);
            celem_index = 1;
            
            % iteration over edges
            for i = 1 : 3*nelem
                row = totalEdge(i,1);
                col = totalEdge(i,2);
                
                temp = Cnode(col,row);
                if temp == 0
                    bndry_nodes(row) = 1;
                    bndry_nodes(col) = 1;
                else
                    icelem(celem_index) = Cnode(row,col);
                    jcelem(celem_index) = temp;
                    kcelem(celem_index) = i;
                    celem_index = celem_index + 1;
                    
                end
            end
            celem_index = celem_index - 1;
            Celem = sparse(icelem(1:celem_index),jcelem(1:celem_index),kcelem(1:celem_index),nelem,nelem);
            bndry_nodes = sparse(bndry_nodes);
            
            
            %% package up the outputs
            obj.node_connectivity = Cnode;
            obj.element_connectivity = Celem;
            obj.has_node_i = has_node_i;
            obj.bndry_nodes = bndry_nodes;
            obj.nb_nodes = nb_nodes;

        end

    end % end methods

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