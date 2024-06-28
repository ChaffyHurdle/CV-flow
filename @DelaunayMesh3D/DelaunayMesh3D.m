classdef DelaunayMesh3D

    %% properties
    properties
        %% Mesh Data
        nodes;
        elements;
        boundary_nodes;
        boundary_faces;
        centroids;

        %% Element properties
        element_measures;
        element_faces;
        face_areas;
        face_normals;

        %% Mesh Counting Properties
        num_nodes;
        num_elements;
        num_faces;
        num_boundary_nodes;
        num_boundary_faces;
    end

    %% methods
    methods

        function obj = DelaunayMesh3D(gmsh_filename,h_max)

            %% extract gmsh mesh properties
            run(gmsh_filename); %runs matlab script output is msh
            p = msh.POS'; 
            t = msh.TETS';

            if nargin == 2

                %% matlab computes new mesh
                model = createpde;
                model.geometryFromMesh(p,t(1:4,:));

                mesh = model.generateMesh(Hmax=h_max,GeometricOrder="linear");
                [p,e,t] = meshToPet(mesh);
            end
                
            obj.nodes = p';
            obj.elements = t(1:4,:)';
            obj.num_nodes = size(p,2);
            obj.num_elements = size(t,2);

            obj = obj.compute_element_faces();
            obj = obj.compute_element_volumes_and_centroids();
            obj = obj.compute_face_areas_and_normals(); 
            obj = obj.compute_boundary();

        end

        function obj = compute_element_faces(obj)

            obj.num_faces = obj.num_elements * 4;

            obj.element_faces = zeros(obj.num_faces,3);

            for i = 1:obj.num_elements

                obj.element_faces(4*(i-1)+1:4*i,:) = nchoosek(obj.elements(i,:),3);
            end

        end

        function obj = compute_element_volumes_and_centroids(obj)

            obj.element_measures = zeros(obj.num_elements,1);
            obj.centroids = zeros(obj.num_elements,3);

            for i =1:obj.num_elements

                local_nodes = obj.nodes(obj.elements(i,:),:);
                a = local_nodes(1,:); b = local_nodes(2,:); 
                c = local_nodes(3,:); d = local_nodes(4,:);

                product = dot((b-a),cross(c-a,d-a));
                obj.element_measures(i) = product/6;

                obj.centroids(i,:) = [mean(local_nodes(:,1)) mean(local_nodes(:,2)) mean(local_nodes(:,3))];

            end


        end

        function obj = compute_face_areas_and_normals(obj)

            obj.face_normals = zeros(obj.num_faces,3);
            obj.face_areas = zeros(obj.num_faces,1); 

            for i =1:obj.num_faces

                local_nodes = obj.nodes(obj.element_faces(i,:),:);
                a = local_nodes(1,:); 
                b = local_nodes(2,:); 
                c = local_nodes(3,:);

                normal = cross(c-a,b-a);

                obj.face_areas(i) = 0.5*norm(normal);

                unit_normal = normal./norm(normal);

                if dot(unit_normal,a-obj.centroids(ceil(i/4),:)) < 0

                    unit_normal = -1 * unit_normal;
                 
                end

                obj.face_normals(i,:) = unit_normal;

            end

        end

        function plot_mesh(obj)

            figure;
            pdeplot3D(obj.nodes',obj.elements');
            view([45 45 45]);

        end

        function obj = compute_boundary(obj)

          %% code adapted from https://www.alecjacobson.com/weblog/1766.html  

          %% extract faces
          element_faces = obj.element_faces;

          %% sort rows so that faces are reorder in ascending order of indices
          sorted_faces = sort(element_faces,2);

          %% determine uniqueness of faces
          [u,m,n] = unique(sorted_faces,'rows');

          %% determine counts for each unique face
          counts = accumarray(n(:), 1);
          %% extract faces that only occurred once
          sorted_exteriorF = u(counts == 1,:);
          %% find in original faces so that ordering of indices is correct
          obj.boundary_faces = find(ismember(sorted_faces,sorted_exteriorF,'rows'));
          obj.num_boundary_faces = length(obj.boundary_faces);

          boundary_nodes = element_faces(obj.boundary_faces,:);
          obj.boundary_nodes = unique(boundary_nodes(:));
          obj.num_boundary_nodes = length(obj.boundary_nodes);
        end

    end

end