function obj = apply_ideal_gas_law(obj)
%% This function applies the ideal gas law to any volumes containing a void

%% Unpacking properties
void_volume = obj.void_volume;
V = obj.volume_class.volume_measures; 
fFactor = obj.volume_fill_percentage;
num_voids = obj.num_voids;

%% boundary conditions
free = obj.pressure_class.active_nodes & ~obj.pressure_class.Dirichlet; 
fixed = find(~free);

%% computing void-free pressure boundary conditions
vent_flag = obj.pressure_class.vent_flag;
vent_idx = obj.pressure_class.vent_idx;
pressure = obj.pressure_class.p_D(obj.pressure_class);

%% Do nothing if no voids present
if num_voids == 0
    obj.pressure_class.pressure = pressure;
    return
end

%% This method requires constant vent pressure
pvent = pressure(vent_idx(1));

volume_of_voids = zeros(size(V));

for i = 1 : num_voids
    void_i = find(void_volume(:,2)==i);
    temp = 0;
    for j = 1 : length(void_i)
        void_ij = void_i(j);
        temp = temp + (1-fFactor(void_ij))*V(void_ij);
    end
    volume_of_voids(void_i) = temp;
end

%% apply the ideal gas law 
for i = 1 : length(fixed)
    bdn_i = fixed(i);
    if void_volume(bdn_i)>0&&~vent_flag(bdn_i)&&volume_of_voids(bdn_i)>0
        pressure(bdn_i) = pvent*void_volume(bdn_i)/volume_of_voids(bdn_i);
    end
end

obj.pressure_class.pressure = pressure;
end