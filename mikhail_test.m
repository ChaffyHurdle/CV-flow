 close all
% Import mesh files
my_mesh = Mesh(p,e,t);

% Darcy rules set
my_darcy = Darcy(0.1, 0.35, 0.2, @permeability);

my_pressure = Pressure(my_mesh,'inlet_location','vent_location','g_D');
my_volume = Volume(my_pressure,my_darcy);
%my_visuals = Visualisation();
%my_options = Optionals();

%% compile CVFEM method
my_cvfem = CVFEM(my_mesh,my_pressure,my_volume,my_darcy,[],[]);

%my_cvfem.solve()

% First set up routine

% Execute code
opt = cvfem2d(opt);

%% Argument set up
function K = permeability(x)
    
    K = [1e-10 0; 0 1e-10];
end
    
    





    