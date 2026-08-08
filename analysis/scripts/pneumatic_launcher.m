%% ==========================================================================
%  ROCKET GLIDER UAV - PNEUMATIC LAUNCHER SIZING
%  2D parametric sweep: launch angle (5-15 deg) x UAV mass (empty -> MTOW)
%
%  Specs: 7 ft span, 4.67 ft^2 wing area, 7.5 ft length, 110 lb MTOW,
%  40 lb payload, 90 KTAS cruise, rocket-glider launch off a pneumatic
%  rail, 15 g max accel, accumulator sized for 3 launches before recharge.
%
%  Sections:
%   1  Unit conversions + spec inputs
%   2  Launch speed (stall speed method)
%   3  Design assumptions (A1-A10)
%   4  Standard catalogue sizes (ISO 6431, EN 286-1)
%   5  Rail length sizing
%   6  2D parametric sweep (angle x mass)
%   7  Worst-case extraction
%   8  Snap to standard sizes
%   9  Bore escalation + envelope coverage check
%   10 Cylinder & piston dimensions
%   11 Accumulator sizing
%   12 Rod buckling check (Euler)
%   13 Mechanical advantage bracket (MA=1 vs MA=2)
%   14 Pressure range summary
%   15 Market comparison
%   16 Contour plots
%   17 Bill of materials
% ==========================================================================

clear; clc; close all;

%% 1. UNIT CONVERSIONS AND SPEC INPUTS

ft_to_m   = 0.3048;
lb_to_kg  = 0.453592;
kts_to_ms = 0.514444;
ft2_to_m2 = 0.092903;

wing_span_m   = 7    * ft_to_m;
wing_area_m2  = 4.67 * ft2_to_m2;
length_m      = 7.5  * ft_to_m;
MTOW_kg       = 110  * lb_to_kg;
payload_kg    = 40   * lb_to_kg;
cruise_ktas   = 90;
cruise_ms     = cruise_ktas * kts_to_ms;
endurance_min = 1.6;
a_max_g       = 15;      % max launch acceleration [g]
n_launches    = 3;       % launches before recharge

g_grav    = 9.81;    % [m/s^2]
E_steel   = 200e9;   % [Pa] steel Young's modulus
rho_air   = 1.225;   % [kg/m^3] sea-level ISA
R_gas     = 287.05;  % [J/(kg K)]

fprintf('=================================================================\n');
fprintf(' ROCKET GLIDER UAV - PNEUMATIC LAUNCHER SIZING ANALYSIS\n');
fprintf('=================================================================\n\n');
fprintf('INPUT SPECIFICATIONS\n');
fprintf('  Wing span          : 7 ft    = %.3f m\n', wing_span_m);
fprintf('  Wing area          : 4.67 ft^2 = %.3f m^2\n', wing_area_m2);
fprintf('  Length             : 7.5 ft   = %.3f m\n', length_m);
fprintf('  MTOW               : 110 lb   = %.2f kg\n', MTOW_kg);
fprintf('  Payload            : 40 lb    = %.2f kg\n', payload_kg);
fprintf('  Cruise speed       : 90 KTAS  = %.1f m/s\n', cruise_ms);
fprintf('  Endurance          : %.1f min\n', endurance_min);
fprintf('  Launch method      : Solid propellant rocket + pneumatic rail\n');
fprintf('  Max acceleration   : %d g\n', a_max_g);
fprintf('  Launches/recharge  : %d\n\n', n_launches);

%% 2. LAUNCH SPEED ESTIMATION
%  V_stall = sqrt(2W / (rho*S*CLmax)); launch speed = 1.3 x V_stall (FAR-23 margin)

CL_max   = 1.4;
W_N      = MTOW_kg * g_grav;
V_stall  = sqrt(2 * W_N / (rho_air * wing_area_m2 * CL_max));
V_launch = 1.3 * V_stall;

fprintf('=================================================================\n');
fprintf(' SECTION 2 - LAUNCH SPEED\n');
fprintf('=================================================================\n');
fprintf('  CL_max assumed     : %.1f\n', CL_max);
fprintf('  Stall speed (MTOW) : %.2f m/s  (%.1f kt)\n', V_stall, V_stall/kts_to_ms);
fprintf('  Launch speed (1.3x Vs): %.2f m/s  (%.1f kt)\n\n', V_launch, V_launch/kts_to_ms);

%% 3. DESIGN ASSUMPTIONS
%  A1  Carriage mass 6 kg           - slim Al sled sized for this airframe
%  A2  Friction mu = 0.05           - PTFE pads on hardened steel rail
%  A3  Transmission efficiency 0.85 - seal/cable/hose losses
%  A4  Mechanical advantage 2:1     - halves piston stroke, doubles force
%  A5  Effective stroke = 70% rail  - remainder reserved for hold-down/end-stop
%  A6  Force FoS = 1.5              - ISO 4414
%  A7  Pressure FoS = 1.25          - max working = rated/FoS
%  A8  30% pressure drop over stroke
%  A9  Cold correction at -20 C vs 25 C reference (ideal gas law)
%  A10 Max system pressure = 10 bar

m_carriage       = 6.0;
mu               = 0.05;
eta              = 0.85;
MA               = 2;
stroke_frac      = 0.70;
FoS_force        = 1.5;
FoS_pressure     = 1.25;
P_drop_factor    = 0.70;
T_op_min_K       = -20 + 273.15;
T_ref_K          = 25  + 273.15;
T_vol_correction = T_op_min_K / T_ref_K;
P_max_rated      = 10e5;   % [Pa]
P_min_op         = 1.5e5;  % [Pa]

fprintf('=================================================================\n');
fprintf(' SECTION 3 - ASSUMPTIONS\n');
fprintf('=================================================================\n');
fprintf('  A1  Carriage mass         : %.0f kg\n',   m_carriage);
fprintf('  A2  Friction coeff mu     : %.2f\n',       mu);
fprintf('  A3  Trans. efficiency eta : %.2f\n',       eta);
fprintf('  A4  Mech. advantage MA    : %d:1\n',       MA);
fprintf('  A5  Effective stroke frac : %.0f%%\n',     stroke_frac*100);
fprintf('  A6  Force FoS             : %.1f\n',       FoS_force);
fprintf('  A7  Pressure FoS          : %.2f\n',       FoS_pressure);
fprintf('  A8  Pressure drop factor  : %.0f%% drop\n', (1-P_drop_factor)*100);
fprintf('  A9  Temp correction       : %.4f  (T=%d C / T=%d C)\n', ...
        T_vol_correction, round(T_op_min_K-273.15), round(T_ref_K-273.15));
fprintf('  A10 Max rated pressure    : %.0f bar\n\n', P_max_rated/1e5);

%% 4. STANDARD CATALOGUE SIZES

ISO_bores_mm   = [32, 40, 50, 63, 80, 100, 125, 160, 200, 250, 320];
ISO_rods_mm    = [12, 16, 20, 25, 32,  36,  50,  63,  80, 100, 125];
ISO_strokes_mm = [100, 125, 160, 200, 250, 320, 400, 500, 630, ...
                  800, 1000, 1250, 1600, 2000];
STD_rail_m     = [2.0, 2.5, 3.0, 3.5, 4.0, 4.5, 5.0, 6.0, ...
                  7.0, 8.0, 9.0, 10.0, 11.0, 12.0];
STD_accum_L    = [1, 2, 4, 6, 8, 10, 12, 16, 20, 25, 30, 40, 50, ...
                  60, 80, 100, 150, 200, 250, 300, 400, 500, ...
                  600, 800, 1000];

fprintf('=================================================================\n');
fprintf(' SECTION 4 - STANDARD CATALOGUE SIZES\n');
fprintf('=================================================================\n');
fprintf('  ISO 6431 bores  [mm]: '); fprintf('%d ', ISO_bores_mm);   fprintf('\n');
fprintf('  ISO 6431 rods   [mm]: '); fprintf('%d ', ISO_rods_mm);    fprintf('\n');
fprintf('  ISO 6431 strokes[mm]: '); fprintf('%d ', ISO_strokes_mm); fprintf('\n');
fprintf('  Rail lengths    [m] : '); fprintf('%.1f ', STD_rail_m);   fprintf('\n');
fprintf('  Accum. sizes    [L] : '); fprintf('%d ', STD_accum_L);    fprintf('\n\n');

%% 5. RAIL LENGTH SIZING
%  v^2 = 2*a*s -> s_min = V_launch^2 / (2*a_max); rail = s_min / stroke_frac,
%  snapped up to nearest standard rail length.

a_max_SI   = a_max_g * g_grav;
L_eff_min  = V_launch^2 / (2 * a_max_SI);
L_rail_min = L_eff_min / stroke_frac;

idx_rail = find(STD_rail_m >= L_rail_min, 1, 'first');
if isempty(idx_rail)
    idx_rail = length(STD_rail_m);
    warning('Rail length exceeds catalogue maximum - using %.1f m', STD_rail_m(end));
end
L_total_rail = STD_rail_m(idx_rail);
L_eff        = stroke_frac * L_total_rail;

a_actual_SI  = V_launch^2 / (2 * L_eff);
a_actual_g   = a_actual_SI / g_grav;

L_piston    = L_eff / MA;
L_piston_mm = L_piston * 1000;

fprintf('=================================================================\n');
fprintf(' SECTION 5 - RAIL LENGTH SIZING\n');
fprintf('=================================================================\n');
fprintf('  Min effective stroke    : %.3f m  (at exactly %d g)\n', L_eff_min, a_max_g);
fprintf('  Min total rail needed   : %.3f m\n', L_rail_min);
fprintf('  -> Selected rail length : %.1f m  (standard)\n', L_total_rail);
fprintf('  Effective accel stroke  : %.3f m\n', L_eff);
if a_actual_g <= a_max_g
    fprintf('  Actual peak accel       : %.2f g  (<= %d g limit CHECK)\n\n', a_actual_g, a_max_g);
else
    fprintf('  WARNING: accel = %.2f g  > %d g LIMIT X\n\n', a_actual_g, a_max_g);
end
fprintf('  Raw piston stroke (L_eff/MA): %.1f mm\n\n', L_piston_mm);

%% 6. 2D PARAMETRIC SWEEP (launch angle x UAV mass)
%  Empty weight ~= MTOW - payload - 10% MTOW propellant, floored at 20 kg.
%  For each (angle, mass): piston force, raw bore, kinetic energy,
%  accumulator volume.

m_empty_est = MTOW_kg - payload_kg - 0.10 * MTOW_kg;
m_empty_est = max(m_empty_est, 20.0);
m_min_sweep = round(m_empty_est);
m_max_sweep = round(MTOW_kg);

theta_vec = 5 : 1 : 15;
mass_vec  = m_min_sweep : 1 : m_max_sweep;
n_theta   = length(theta_vec);
n_mass    = length(mass_vec);

bore_matrix     = zeros(n_theta, n_mass);
F_piston_matrix = zeros(n_theta, n_mass);
KE_matrix       = zeros(n_theta, n_mass);
V_acc_matrix    = zeros(n_theta, n_mass);
accel_g_matrix  = zeros(n_theta, n_mass);

thermo_eff = 0.90;                    % expansion (thermodynamic) efficiency
ln_ratio   = log(1 / P_drop_factor);  % isothermal expansion term

fprintf('=================================================================\n');
fprintf(' SECTION 6 - 2D PARAMETRIC SWEEP\n');
fprintf('=================================================================\n');
fprintf('  Angle sweep  : %d to %d deg  (%d values)\n', ...
        theta_vec(1), theta_vec(end), n_theta);
fprintf('  Mass sweep   : %d kg to %d kg  (%d values)\n', ...
        mass_vec(1), mass_vec(end), n_mass);
fprintf('  Combinations : %d\n\n', n_theta * n_mass);

for i = 1 : n_theta
    theta_rad = deg2rad(theta_vec(i));

    for j = 1 : n_mass
        m_uav   = mass_vec(j);
        m_total = m_uav + m_carriage;

        % Required acceleration to reach V_launch over the effective stroke
        a_req = V_launch^2 / (2 * L_eff);
        accel_g_matrix(i,j) = a_req / g_grav;

        % Force balance: inertia + gravity component + friction
        F_inertia  = m_total * a_req;
        F_gravity  = m_total * g_grav * sin(theta_rad);
        F_friction = mu * m_total * g_grav * cos(theta_rad);
        F_total    = F_inertia + F_gravity + F_friction;

        % Structural FoS, then back out piston force through MA and eta
        F_design   = F_total * FoS_force;
        F_piston   = F_design / (MA * eta);
        F_piston_matrix(i,j) = F_piston;

        % Kinetic energy imparted (angle-independent)
        KE = 0.5 * m_total * V_launch^2;
        KE_matrix(i,j) = KE;

        % Raw bore from F = P*A
        A_min = F_piston / P_max_rated;
        D_raw = sqrt(4 * A_min / pi) * 1000;
        bore_matrix(i,j) = D_raw;

        % Accumulator volume: isothermal expansion, cold-corrected
        E_needed = KE / (eta * thermo_eff);
        V_raw    = E_needed / (P_max_rated * ln_ratio);
        V_raw_L  = V_raw * 1000;
        V_cold   = V_raw_L / T_vol_correction;
        V_acc_matrix(i,j) = V_cold;
    end
end

fprintf('  Sweep complete.\n\n');

%% 7. WORST-CASE EXTRACTION

[WC_bore_raw, idx_bore_flat] = max(bore_matrix(:));
[WC_bore_i, WC_bore_j]       = ind2sub(size(bore_matrix), idx_bore_flat);
WC_bore_angle = theta_vec(WC_bore_i);
WC_bore_mass  = mass_vec(WC_bore_j);

[WC_vacc, idx_vacc_flat] = max(V_acc_matrix(:));
[WC_vacc_i, WC_vacc_j]   = ind2sub(size(V_acc_matrix), idx_vacc_flat);
WC_vacc_angle = theta_vec(WC_vacc_i);
WC_vacc_mass  = mass_vec(WC_vacc_j);

[WC_Fpiston, idx_F_flat] = max(F_piston_matrix(:));
[WC_F_i, WC_F_j]         = ind2sub(size(F_piston_matrix), idx_F_flat);
WC_F_angle = theta_vec(WC_F_i);
WC_F_mass  = mass_vec(WC_F_j);

WC_KE = max(KE_matrix(:));

fprintf('=================================================================\n');
fprintf(' SECTION 7 - WORST-CASE VALUES ACROSS FULL ENVELOPE\n');
fprintf('=================================================================\n');
fprintf('  Worst bore demand   : %.2f mm   at angle=%.0f deg, mass=%.0f kg\n', ...
        WC_bore_raw, WC_bore_angle, WC_bore_mass);
fprintf('  Worst piston force  : %.0f N     at angle=%.0f deg, mass=%.0f kg\n', ...
        WC_Fpiston, WC_F_angle, WC_F_mass);
fprintf('  Worst accum vol (1x): %.2f L    at angle=%.0f deg, mass=%.0f kg\n', ...
        WC_vacc, WC_vacc_angle, WC_vacc_mass);
fprintf('  Worst KE            : %.0f J\n\n', WC_KE);

%% 8. SNAP TO STANDARD SIZES

idx_bore_std = find(ISO_bores_mm >= WC_bore_raw, 1, 'first');
if isempty(idx_bore_std), idx_bore_std = length(ISO_bores_mm); end
std_bore_mm  = ISO_bores_mm(idx_bore_std);
std_rod_mm   = ISO_rods_mm(idx_bore_std);

stroke_is_custom = (L_piston_mm > ISO_strokes_mm(end));
if stroke_is_custom
    std_stroke_mm = ceil(L_piston_mm / 100) * 100;   % round to nearest 100 mm
    stroke_note   = '(CUSTOM - above ISO catalogue max 2000 mm; special order required)';
else
    idx_stroke = find(ISO_strokes_mm >= L_piston_mm, 1, 'first');
    std_stroke_mm = ISO_strokes_mm(idx_stroke);
    stroke_note   = '(ISO 6431 catalogue size)';
end

idx_vacc1 = find(STD_accum_L >= WC_vacc, 1, 'first');
if isempty(idx_vacc1), idx_vacc1 = length(STD_accum_L); end
std_vessel_single_L = STD_accum_L(idx_vacc1);

V_acc_total_raw = WC_vacc * n_launches;
idx_vacc3 = find(STD_accum_L >= V_acc_total_raw, 1, 'first');
if isempty(idx_vacc3), idx_vacc3 = length(STD_accum_L); end
std_vessel_total_L = STD_accum_L(idx_vacc3);

fprintf('=================================================================\n');
fprintf(' SECTION 8 - SNAPPED TO STANDARD SIZES (initial)\n');
fprintf('=================================================================\n');
fprintf('  Raw bore   %.2f mm  -> ISO std bore  : %d mm\n',   WC_bore_raw, std_bore_mm);
fprintf('  Raw stroke %.1f mm  -> Std stroke    : %d mm  %s\n', L_piston_mm, std_stroke_mm, stroke_note);
fprintf('  Raw vol    %.2f L   -> Single vessel : %d L\n',   WC_vacc, std_vessel_single_L);
fprintf('  Raw x%d    %.2f L   -> 3-launch vessel: %d L\n\n', n_launches, V_acc_total_raw, std_vessel_total_L);

%% 9. BORE ESCALATION + ENVELOPE COVERAGE CHECK
%  Confirm the snapped bore covers every grid point at <= rated/FoS pressure;
%  escalate bore size if not.

P_work_max = P_max_rated / FoS_pressure;

for i_esc = idx_bore_std : length(ISO_bores_mm)
    std_bore_mm   = ISO_bores_mm(i_esc);
    std_rod_mm    = ISO_rods_mm(i_esc);
    A_std_bore    = pi/4 * (std_bore_mm/1000)^2;
    P_work_actual = WC_Fpiston / A_std_bore;
    F_available   = P_work_max * A_std_bore;
    coverage_matrix = (F_piston_matrix <= F_available);
    all_covered     = all(coverage_matrix(:));
    if all_covered
        break
    end
end

n_uncovered = sum(~coverage_matrix(:));

fprintf('=================================================================\n');
fprintf(' SECTION 9 - ENVELOPE COVERAGE CHECK\n');
fprintf('=================================================================\n');
fprintf('  Selected bore area  : %.6f m^2  (D = %d mm)\n', A_std_bore, std_bore_mm);
fprintf('  Working pressure    : %.2f bar  (at std bore)\n', P_work_actual/1e5);
fprintf('  Max allowable work P: %.2f bar  (%d bar / FoS %.2f)\n', ...
        P_work_max/1e5, round(P_max_rated/1e5), FoS_pressure);
fprintf('  Max force available : %.0f N\n', F_available);
fprintf('  Max force required  : %.0f N\n', WC_Fpiston);
if all_covered
    fprintf('  Coverage status     : ALL %d grid points COVERED CHECK\n\n', n_theta*n_mass);
else
    fprintf('  Coverage status     : %d points NOT COVERED X\n\n', n_uncovered);
end

%% 10. CYLINDER AND PISTON PHYSICAL DIMENSIONS
%  Wall thickness from thin-wall pressure vessel formula, t = P*D/(2*S_allow),
%  S_allow = sigma_yield/3 (ASME) with mild steel sigma_yield = 250 MPa.

S_allow      = 250e6 / 3.0;
cyl_wall_mm  = (P_max_rated * std_bore_mm/1000) / (2 * S_allow) * 1000;
cyl_OD_mm    = std_bore_mm + 2 * cyl_wall_mm;

cyl_gland_mm   = 1.5 * std_bore_mm;
cyl_endcap_mm  = 1.0 * std_bore_mm;
cyl_total_mm   = std_stroke_mm + cyl_gland_mm + cyl_endcap_mm;

piston_OD_mm    = std_bore_mm - 0.05;   % 0.05 mm clearance
piston_thick_mm = 0.4 * std_bore_mm;    % rule of thumb

fprintf('=================================================================\n');
fprintf(' SECTION 10 - CYLINDER & PISTON DIMENSIONS\n');
fprintf('=================================================================\n');
fprintf('  CYLINDER (ISO 6431)\n');
fprintf('  %-30s %d mm\n',   'Bore (ID):',         std_bore_mm);
fprintf('  %-30s %.1f mm\n', 'Wall thickness:',     cyl_wall_mm);
fprintf('  %-30s %.1f mm\n', 'Outer diameter (OD):', cyl_OD_mm);
fprintf('  %-30s %.0f mm\n', 'Total body length:',  cyl_total_mm);
fprintf('     Stroke             : %d mm\n',         std_stroke_mm);
fprintf('     Gland / rod seal   : %.0f mm\n',       cyl_gland_mm);
fprintf('     End cap allowance  : %.0f mm\n\n',     cyl_endcap_mm);
fprintf('  PISTON\n');
fprintf('  %-30s %.2f mm\n', 'Piston OD:',          piston_OD_mm);
fprintf('  %-30s %.1f mm\n', 'Piston thickness:',   piston_thick_mm);
fprintf('  %-30s %d mm\n',   'Rod diameter:',        std_rod_mm);
fprintf('  %-30s %d mm\n\n', 'Rod length (= stroke):', std_stroke_mm);

%% 11. ACCUMULATOR SIZING (3 launches before recharge)
%  Cylindrical vessel, L/D = 3: V = (3*pi/4)*D^3 -> D = (4V/(3*pi))^(1/3)

AR_vessel       = 3.0;
V_total_m3      = std_vessel_total_L / 1000;
D_vessel_m      = (4 * V_total_m3 / (pi * AR_vessel))^(1/3);
D_vessel_mm     = D_vessel_m * 1000;
L_vessel_mm     = AR_vessel * D_vessel_mm;
vessel_wall_mm  = (P_max_rated * D_vessel_m) / (2 * S_allow) * 1000;
vessel_OD_mm    = D_vessel_mm + 2 * vessel_wall_mm;

fprintf('=================================================================\n');
fprintf(' SECTION 11 - ACCUMULATOR SIZING (%d launches)\n', n_launches);
fprintf('=================================================================\n');
fprintf('  Volume per launch (raw)    : %.2f L\n',  WC_vacc);
fprintf('  Std vessel (1 launch)      : %d L\n',    std_vessel_single_L);
fprintf('  Volume for %d launches (raw): %.2f L\n', n_launches, V_acc_total_raw);
fprintf('  --> Std vessel selected    : %d L\n\n',  std_vessel_total_L);
fprintf('  ACCUMULATOR GEOMETRY (cylindrical, L/D = %.0f)\n', AR_vessel);
fprintf('  %-30s %.1f mm\n', 'Internal diameter:',  D_vessel_mm);
fprintf('  %-30s %.1f mm\n', 'Internal length:',    L_vessel_mm);
fprintf('  %-30s %.1f mm\n', 'Wall thickness:',     vessel_wall_mm);
fprintf('  %-30s %.1f mm\n\n', 'Outer diameter (OD):', vessel_OD_mm);

%% 12. ROD BUCKLING CHECK (Euler pin-pin column)
%  F_cr = pi^2 * E * I / L^2, target FoS_buckling > 4.0

d_rod_m  = std_rod_mm / 1000;
I_rod    = pi * d_rod_m^4 / 64;
L_rod    = std_stroke_mm / 1000;
F_cr     = (pi^2 * E_steel * I_rod) / L_rod^2;
FoS_buck = F_cr / WC_Fpiston;

fprintf('=================================================================\n');
fprintf(' SECTION 12 - ROD BUCKLING CHECK\n');
fprintf('=================================================================\n');
fprintf('  Rod diameter           : %d mm\n',   std_rod_mm);
fprintf('  Rod length (= stroke)  : %d mm\n',   std_stroke_mm);
fprintf('  Second moment I        : %.4e m^4\n', I_rod);
fprintf('  Euler critical load    : %.0f N\n',  F_cr);
fprintf('  Working piston force   : %.0f N\n',  WC_Fpiston);
fprintf('  Buckling FoS           : %.1f  ',    FoS_buck);
if FoS_buck > 4.0
    fprintf('CHECK (target > 4.0)\n\n');
else
    fprintf('X WARNING: below 4.0 - consider larger rod or shorter stroke\n\n');
end

%% 13. MECHANICAL ADVANTAGE BRACKET (MA=1 vs MA=2)

fprintf('=================================================================\n');
fprintf(' SECTION 13 - MECHANICAL ADVANTAGE BRACKET\n');
fprintf('=================================================================\n');
fprintf('%-6s %-16s %-14s %-14s %-22s\n', ...
        'MA', 'Piston F [N]', 'Raw bore [mm]', 'Std bore [mm]', 'Stroke');
fprintf('%s\n', repmat('-', 1, 74));

WC_F_total = WC_Fpiston * MA * eta;   % total carriage force, back-calculated

for MA_test = [1, 2]
    F_pis_test  = WC_F_total / (MA_test * eta);
    A_test      = F_pis_test / P_max_rated;
    D_test_mm   = sqrt(4 * A_test / pi) * 1000;

    idx_tb = find(ISO_bores_mm >= D_test_mm, 1, 'first');
    if isempty(idx_tb), idx_tb = length(ISO_bores_mm); end
    std_bore_MA = ISO_bores_mm(idx_tb);

    stroke_test_mm = (L_eff / MA_test) * 1000;
    if stroke_test_mm > ISO_strokes_mm(end)
        stroke_str = sprintf('%.0f mm (CUSTOM, > ISO max 2000)', stroke_test_mm);
    elseif any(ISO_strokes_mm == round(stroke_test_mm))
        stroke_str = sprintf('%d mm (standard ISO)', round(stroke_test_mm));
    else
        idx_sc = find(ISO_strokes_mm >= stroke_test_mm, 1, 'first');
        stroke_str = sprintf('%d mm (snap-up from %.0f)', ISO_strokes_mm(idx_sc), stroke_test_mm);
    end

    fprintf('%-6d %-16.0f %-14.1f %-14d %-22s\n', ...
            MA_test, F_pis_test, D_test_mm, std_bore_MA, stroke_str);
end
fprintf('\n');
fprintf('Note: MA=%d used for final sizing. Stroke = %.0f mm - %s\n\n', ...
        MA, L_piston_mm, stroke_note);

%% 14. PRESSURE RANGE SUMMARY

P_op_range_min = P_min_op;
P_op_range_max = P_work_max;
P_rated        = P_max_rated;

fprintf('=================================================================\n');
fprintf(' SECTION 14 - PRESSURE RANGE\n');
fprintf('=================================================================\n');
fprintf('  Minimum operating    : %.1f bar  (seal/valve breakout)\n', P_op_range_min/1e5);
fprintf('  Working (std bore)   : %.2f bar\n',  P_work_actual/1e5);
fprintf('  Maximum working      : %.1f bar  (rated %.0f bar / FoS %.2f)\n', ...
        P_op_range_max/1e5, P_rated/1e5, FoS_pressure);
fprintf('  Rated maximum        : %.0f bar\n\n', P_rated/1e5);

%% 15. MARKET COMPARISON

fprintf('=================================================================\n');
fprintf(' SECTION 15 - MARKET COMPARISON\n');
fprintf('=================================================================\n');
fprintf('\n  CYLINDERS (ISO 6431)\n');
fprintf('  Required: Bore %d mm / Rod %d mm / Stroke %d mm / >= %.1f bar\n\n', ...
        std_bore_mm, std_rod_mm, std_stroke_mm, P_work_actual/1e5);
fprintf('  %-18s %-30s %-10s %-22s %-10s %s\n', ...
        'Manufacturer','Part Number','Max P','Temp Rating','Standard','Note');
fprintf('  %s\n', repmat('-', 1, 100));
fprintf('  %-18s %-30s %-10s %-22s %-10s %s\n', ...
        'Parker Hannifin', ...
        sprintf('P1D-S0%dMS%d', std_bore_mm, std_stroke_mm), ...
        '16 bar','-40C (Viton seal)','ISO 6431','Best choice');
fprintf('  %-18s %-30s %-10s %-22s %-10s %s\n', ...
        'Bosch Rexroth', ...
        sprintf('CDL1MP5/%03dA%d', std_bore_mm, std_stroke_mm), ...
        '16 bar','-40C (HNBR opt.)','ISO 6431','Best choice');
fprintf('  %-18s %-30s %-10s %-22s %-10s %s\n', ...
        'Festo', ...
        sprintf('DNC-%d-%d-PPV-A', std_bore_mm, std_stroke_mm), ...
        '12 bar','Low-temp kit req.','ISO 6431','Check stroke avail.');
fprintf('  %-18s %-30s %-10s %-22s %-10s %s\n', ...
        'SMC', ...
        sprintf('C95SDB%03d-%d', std_bore_mm, std_stroke_mm), ...
        '10 bar','Marginal -15C','ISO 6431','Check P-rating');
fprintf('  %-18s %-30s %-10s %-22s %-10s %s\n', ...
        'PHD Inc.', ...
        sprintf('AV%dx%d', std_bore_mm, std_stroke_mm), ...
        '14 bar','-29C std.','NFPA/ISO','Available');

if stroke_is_custom
    fprintf('\n  *** STROKE %d mm exceeds ISO catalogue max (2000 mm). ***\n', std_stroke_mm);
    fprintf('  *** Parker and Bosch Rexroth both offer custom long-stroke cylinders. ***\n');
    fprintf('  *** Alternatively, increase MA to 4:1 to halve stroke to ~%.0f mm. ***\n\n', L_piston_mm/2);
end

fprintf('\n  ACCUMULATORS / PRESSURE VESSELS  (%d L, %.0f bar)\n\n', ...
        std_vessel_total_L, P_rated/1e5);
fprintf('  %-18s %-32s %-10s %-28s %-16s %s\n', ...
        'Manufacturer','Part Number','Volume','Pressure','Standard','Notes');
fprintf('  %s\n', repmat('-', 1, 115));
fprintf('  %-18s %-32s %-10s %-28s %-16s %s\n', ...
        'Hydac', ...
        sprintf('SBO%d-1E1/112U-330A', std_vessel_total_L), ...
        sprintf('%d L', std_vessel_total_L), ...
        '330 bar rated / 10 bar working','EN 14359','Bladder, fast discharge');
fprintf('  %-18s %-32s %-10s %-28s %-16s %s\n', ...
        'Parker', ...
        sprintf('ACCA%d', std_vessel_total_L), ...
        sprintf('%d L', std_vessel_total_L), ...
        '350 bar rated / 10 bar working','PED 2014/68/EU','Piston, low-temp');
fprintf('  %-18s %-32s %-10s %-28s %-16s %s\n', ...
        'Bosch Rexroth', ...
        sprintf('HAB%d', std_vessel_total_L), ...
        sprintf('%d L', std_vessel_total_L), ...
        '350 bar rated / 10 bar working','EN 286-1','Diaphragm type');
fprintf('  %-18s %-32s %-10s %-28s %-16s %s\n', ...
        'Festo', ...
        sprintf('CRVZS-%d', std_vessel_total_L), ...
        sprintf('%d L', std_vessel_total_L), ...
        '16 bar rated','PED CE','Pneumatic buffer vessel');
fprintf('  %-18s %-32s %-10s %-28s %-16s %s\n', ...
        'Generic EN 286-1', ...
        sprintf('PV-%dL-10B', std_vessel_total_L), ...
        sprintf('%d L', std_vessel_total_L), ...
        '10 bar working (exact match)','EN 286-1','Preferred, cost-effective');
fprintf('\n');

%% 16. CONTOUR PLOTS
%  Plot 1: bore diameter [mm]   Plot 2: piston force [N]
%  Plot 3: accumulator volume [L]   Plot 4: kinetic energy [J]
%  Red star = worst-case design point.

figure('Name', 'Rocket Glider Launcher - 2D Parametric Sweep', ...
       'Position', [80, 80, 1280, 900]);

subplot(2, 2, 1);
contourf(mass_vec, theta_vec, bore_matrix, 25, 'LineColor', 'none');
colorbar;
hold on;
contour(mass_vec, theta_vec, bore_matrix, ISO_bores_mm, ...
        'LineColor', 'k', 'LineWidth', 1.5, 'ShowText', 'on');
plot(WC_bore_mass, WC_bore_angle, 'r*', 'MarkerSize', 14, 'LineWidth', 2);
contour(mass_vec, theta_vec, bore_matrix, [std_bore_mm std_bore_mm], ...
        'LineColor', 'r', 'LineWidth', 2.0);
xlabel('UAV mass [kg]', 'FontSize', 11);
ylabel('Launch angle [deg]', 'FontSize', 11);
title(sprintf('Required bore diameter [mm]\n(ISO contours - selected %d mm = red line)', std_bore_mm), ...
      'FontSize', 10);
colormap(subplot(2,2,1), parula);
grid on;

subplot(2, 2, 2);
contourf(mass_vec, theta_vec, F_piston_matrix/1000, 25, 'LineColor', 'none');
colorbar;
hold on;
plot(WC_F_mass, WC_F_angle, 'r*', 'MarkerSize', 14, 'LineWidth', 2);
xlabel('UAV mass [kg]', 'FontSize', 11);
ylabel('Launch angle [deg]', 'FontSize', 11);
title(sprintf('Piston force required [kN]\n(worst case = red star, F_{max} = %.1f kN)', WC_Fpiston/1000), ...
      'FontSize', 10);
colormap(subplot(2,2,2), hot);
grid on;

subplot(2, 2, 3);
contourf(mass_vec, theta_vec, V_acc_matrix, 25, 'LineColor', 'none');
colorbar;
hold on;
accum_contour_levels = [50, 100, 150, 200, 250, 300, 400, 500];
valid_levels = accum_contour_levels(accum_contour_levels <= max(V_acc_matrix(:)));
if ~isempty(valid_levels)
    contour(mass_vec, theta_vec, V_acc_matrix, valid_levels, ...
            'LineColor', 'k', 'LineWidth', 1.5, 'ShowText', 'on');
end
plot(WC_vacc_mass, WC_vacc_angle, 'r*', 'MarkerSize', 14, 'LineWidth', 2);
xlabel('UAV mass [kg]', 'FontSize', 11);
ylabel('Launch angle [deg]', 'FontSize', 11);
title(sprintf('Accumulator vol per launch [L]\n(worst case %.0f L -> std vessel %d L)', ...
      WC_vacc, std_vessel_single_L), 'FontSize', 10);
colormap(subplot(2,2,3), cool);
grid on;

subplot(2, 2, 4);
contourf(mass_vec, theta_vec, KE_matrix/1000, 25, 'LineColor', 'none');
colorbar;
hold on;
contour(mass_vec, theta_vec, KE_matrix/1000, 6, ...
        'LineColor', 'k', 'LineWidth', 1.0, 'ShowText', 'on');
xlabel('UAV mass [kg]', 'FontSize', 11);
ylabel('Launch angle [deg]', 'FontSize', 11);
title(sprintf('Kinetic energy [kJ]\n(angle-independent - contours are vertical)'), ...
      'FontSize', 10);
colormap(subplot(2,2,4), jet);
grid on;

sgtitle(sprintf('Rocket Glider UAV - 2D Parametric Sweep  |  Rail %.1f m  |  Bore %d mm  |  %d-%d deg', ...
        L_total_rail, std_bore_mm, theta_vec(1), theta_vec(end)), ...
        'FontSize', 13, 'FontWeight', 'bold');

%% FILE EXPORT
%  Timestamped exports so repeated runs don't overwrite each other:
%  PNG plots, full grid results (CSV), worst-case summary (CSV), text report.

output_dir  = './output';
figures_dir = fullfile(output_dir, 'figures');
tables_dir  = fullfile(output_dir, 'tables');
reports_dir = fullfile(output_dir, 'reports');

for d = {output_dir, figures_dir, tables_dir, reports_dir}
    if ~isfolder(d{1}), mkdir(d{1}); end
end

timestamp     = datetime('now', 'Format', 'yyyy-MM-dd_HHmmss');
timestamp_str = string(timestamp);

fprintf('=================================================================\n');
fprintf(' SAVING RESULTS TO FILES\n');
fprintf('=================================================================\n\n');

% Plots
fig_filename = fullfile(figures_dir, sprintf('RocketGlider_Sweep_Plots_%s.png', timestamp_str));
saveas(gcf, fig_filename, 'png');
fprintf('  Contour plots saved to:\n    %s\n\n', fig_filename);

% Full results grid (one row per angle/mass combination)
csv_filename = fullfile(tables_dir, sprintf('component_sizing_results_%s.csv', timestamp_str));
results_table = table(...
    repmat(theta_vec', length(mass_vec), 1), ...
    repelem(mass_vec', length(theta_vec)), ...
    bore_matrix(:), ...
    F_piston_matrix(:), ...
    V_acc_matrix(:), ...
    KE_matrix(:), ...
    accel_g_matrix(:), ...
    'VariableNames', {'Angle_deg', 'Mass_kg', 'Bore_mm', 'Force_N', 'Volume_L', 'KE_J', 'Accel_g'});
writetable(results_table, csv_filename);
fprintf('  Full results (%d grid points) saved to:\n    %s\n\n', ...
        length(bore_matrix(:)), csv_filename);

% Worst-case summary
summary_csv_filename = fullfile(tables_dir, sprintf('worst_case_summary_%s.csv', timestamp_str));
summary_table = table(...
    {'Bore'; 'Force'; 'Accumulator'; 'Kinetic Energy'}, ...
    [WC_bore_raw; WC_Fpiston; WC_vacc; WC_KE], ...
    {'mm'; 'N'; 'L'; 'J'}, ...
    [WC_bore_mass; WC_F_mass; WC_vacc_mass; WC_vacc_mass], ...
    [WC_bore_angle; WC_F_angle; WC_vacc_angle; WC_vacc_angle], ...
    'VariableNames', {'Parameter', 'Value', 'Unit', 'At_Mass_kg', 'At_Angle_deg'});
writetable(summary_table, summary_csv_filename);
fprintf('  Worst-case summary saved to:\n    %s\n\n', summary_csv_filename);

% Human-readable analysis report
summary_txt_filename = fullfile(reports_dir, sprintf('analysis_summary_%s.txt', timestamp_str));
fid = fopen(summary_txt_filename, 'w');
fprintf(fid, '=================================================================\n');
fprintf(fid, ' PARAMETRIC SWEEP ANALYSIS SUMMARY\n');
fprintf(fid, '=================================================================\n\n');
fprintf(fid, 'Analysis timestamp: %s\n', timestamp);
fprintf(fid, 'Total grid points: %d (%d angles x %d masses)\n\n', ...
        n_theta*n_mass, n_theta, n_mass);
fprintf(fid, 'WORST-CASE DESIGN POINTS:\n');
fprintf(fid, '  Bore demand:        %.2f mm at %.0f kg @ %.0f deg\n', WC_bore_raw, WC_bore_mass, WC_bore_angle);
fprintf(fid, '  Force requirement:  %.0f N at %.0f kg @ %.0f deg\n', WC_Fpiston, WC_F_mass, WC_F_angle);
fprintf(fid, '  Accumulator volume: %.0f L at %.0f kg @ %.0f deg\n', WC_vacc, WC_vacc_mass, WC_vacc_angle);
fprintf(fid, '  Kinetic energy:     %.0f J at %.0f kg @ %.0f deg\n\n', WC_KE, WC_vacc_mass, WC_vacc_angle);
fprintf(fid, 'COMPONENT SIZING (ISO STANDARD):\n');
fprintf(fid, '  Bore: %d mm (calculated %.2f mm)\n', std_bore_mm, WC_bore_raw);
fprintf(fid, '  Stroke: %d mm (calculated %.0f mm)\n', std_stroke_mm, L_piston_mm);
fprintf(fid, '  Accumulator: %d L (calculated %.0f L)\n', std_vessel_total_L, WC_vacc);
fprintf(fid, '  Working pressure: %.2f bar (max allowable %.1f bar)\n\n', ...
        P_work_actual/1e5, P_op_range_max/1e5);
fprintf(fid, 'VERIFICATION:\n');
fprintf(fid, '  Envelope coverage: %d/%d grid points covered\n', n_theta*n_mass - n_uncovered, n_theta*n_mass);
fprintf(fid, '  Buckling FoS: %.1f (target > 4.0)\n', FoS_buck);
fprintf(fid, '  Pressure FoS: %.2f (applied)\n', FoS_pressure);
fprintf(fid, '  Force FoS: %.1f (applied)\n\n', FoS_force);
fprintf(fid, 'RECOMMENDED COMPONENTS:\n');
fprintf(fid, '  Cylinder: Parker P1D-S0%dMS%d or Bosch Rexroth CDL1MP5/%03dA%d\n', ...
        std_bore_mm, std_stroke_mm, std_bore_mm, std_stroke_mm);
fprintf(fid, '  Accumulator: EN 286-1 standard %d L @ 10 bar (or Hydac SBO%d)\n\n', ...
        std_vessel_total_L, std_vessel_total_L);
fprintf(fid, '=================================================================\n');
fclose(fid);
fprintf('  Analysis summary saved to:\n    %s\n\n', summary_txt_filename);

fprintf('=================================================================\n');
fprintf(' FILE EXPORT COMPLETE\n');
fprintf('=================================================================\n\n');

%% 17. FINAL BILL OF MATERIALS

fprintf('=================================================================\n');
fprintf(' FINAL BILL OF MATERIALS\n');
fprintf(' Rocket Glider UAV Pneumatic Launcher\n');
fprintf('=================================================================\n\n');

fprintf('  GEOMETRY\n');
fprintf('  %-38s %.0f mm  (%.1f m)\n', 'Total rail length:', ...
        L_total_rail*1000, L_total_rail);
fprintf('  %-38s %.0f mm  (%.2f m)\n', 'Effective acceleration stroke:', ...
        L_eff*1000, L_eff);
fprintf('  %-38s %.2f g\n\n', 'Actual peak acceleration:', a_actual_g);

fprintf('  LAUNCH SPEED\n');
fprintf('  %-38s %.2f m/s  (%.1f kt)\n', 'Stall speed (at MTOW):', ...
        V_stall, V_stall/kts_to_ms);
fprintf('  %-38s %.2f m/s  (%.1f kt)\n\n', 'Launch speed (1.3 x Vs):', ...
        V_launch, V_launch/kts_to_ms);

fprintf('  PISTON CYLINDER  (ISO 6431)\n');
fprintf('  %-38s %d mm\n',  'Bore diameter (ID):',       std_bore_mm);
fprintf('  %-38s %.1f mm\n','Wall thickness:',             cyl_wall_mm);
fprintf('  %-38s %.1f mm\n','Outer diameter (OD):',        cyl_OD_mm);
fprintf('  %-38s %d mm\n',  'Rod diameter:',               std_rod_mm);
fprintf('  %-38s %d mm\n',  'Stroke:',                     std_stroke_mm);
fprintf('  %-38s %.0f mm\n','Total cylinder body length:', cyl_total_mm);
fprintf('  %-38s %.2f mm\n','Piston OD:',                  piston_OD_mm);
fprintf('  %-38s %.1f mm\n','Piston thickness:',           piston_thick_mm);
fprintf('  %-38s %d:1\n\n', 'Mechanical advantage:',       MA);

fprintf('  PRESSURE VESSEL  (EN 286-1)\n');
fprintf('  %-38s %d L  (for %d launches)\n', 'Accumulator volume:', ...
        std_vessel_total_L, n_launches);
fprintf('  %-38s %.1f mm\n','Internal diameter:',           D_vessel_mm);
fprintf('  %-38s %.1f mm\n','Internal length:',             L_vessel_mm);
fprintf('  %-38s %.1f mm\n','Wall thickness:',              vessel_wall_mm);
fprintf('  %-38s %.1f mm\n\n','Outer diameter (OD):',       vessel_OD_mm);

fprintf('  PRESSURE RANGE\n');
fprintf('  %-38s %.1f bar\n',  'Minimum operating:',      P_op_range_min/1e5);
fprintf('  %-38s %.2f bar\n',  'Working (worst case, std bore):', P_work_actual/1e5);
fprintf('  %-38s %.1f bar\n',  'Maximum working (rated/FoS):', P_op_range_max/1e5);
fprintf('  %-38s %.0f bar\n\n','Rated maximum:',           P_rated/1e5);

fprintf('  FACTORS OF SAFETY\n');
fprintf('  %-38s %.1f\n',  'Force FoS:',          FoS_force);
fprintf('  %-38s %.2f\n',  'Pressure FoS:',        FoS_pressure);
fprintf('  %-38s %.1f\n\n','Rod buckling FoS:',    FoS_buck);

fprintf('  WORST-CASE DESIGN POINTS\n');
fprintf('  %-38s %.0f kg at %.0f deg\n', 'Bore sizing governed by:', ...
        WC_bore_mass, WC_bore_angle);
fprintf('  %-38s %.0f kg at %.0f deg\n', 'Volume sizing governed by:', ...
        WC_vacc_mass, WC_vacc_angle);
fprintf('  %-38s %.0f kg at %.0f deg\n\n', 'Force sizing governed by:', ...
        WC_F_mass, WC_F_angle);

fprintf('  MARKET RECOMMENDATIONS\n');
fprintf('  Cylinder    : Parker P1D-S0%dMS%d  or  Bosch Rexroth CDL1MP5/%03dA%d\n', ...
        std_bore_mm, std_stroke_mm, std_bore_mm, std_stroke_mm);
if stroke_is_custom
    fprintf('  NOTE        : Stroke %d mm is a CUSTOM order (> ISO catalogue max 2000 mm)\n', std_stroke_mm);
end
fprintf('  Accumulator : EN 286-1 vessel %d L @ 10 bar  (or Hydac SBO%d)\n', ...
        std_vessel_total_L, std_vessel_total_L);
fprintf('\n');

fprintf('=================================================================\n');
fprintf(' ANALYSIS COMPLETE\n');
fprintf('=================================================================\n');
