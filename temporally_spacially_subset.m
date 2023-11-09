% Fetch h5 data specified file path.   Spatially and temporally subset
% those data as requested.   Then save the new subsetted data in newly
% specifid h5 file location.
% It WILL NOT overwite data files that already exist.  But it may add to
% them.   It is best to make sure that all files you are trying to write do
% not yet exist.

% file_path      the path to where the large dataset is
% save_file      the location where the subsetted data should be saved
% lat_long       [lat_1, long_1, lat_2, long 2] TWo corners of a square 
%                   defining desired sub area
% days           [start_day, end_day]  Start and end are int 1->365.  Where 
%                   1 is begining of large dataset (irregardless of time of 
%                   year) Ned Bair's data generally starts of "winter" (aka
%                   in fall) not begining of year calendar year
% metavariable   The variable specifying type of data.  'SWE', 'melt', or
%                    'sweHybrid'
function temporally_spacially_subset(file_path, save_file, ...
    lat_long, days, metavariable)

p1 = lat_long(1:2);
p2 = lat_long(3:4);
start_day = days(1);
end_day = days(2);
number_days = end_day - start_day;
if start_day > 365 || start_day + number_days > 365 || number_days < 1 || end_day > 365
    error('Days given are invalid')
end

proj = build_Projection(file_path);
% Retrieves the small grid and a reference raster object
[small_grid, small_RefRaster] = getmelt_specifc_region( ...
                                    file_path, metavariable, p1, ...
                                    p2, start_day, number_days);

% Creates the date arrays for the subestted data
large_matlab_dates = h5readatt(file_path, '/', 'MATLABdates');
large_iso_dates = h5readatt(file_path, '/', 'ISOdates');
small_matlab_dates = large_matlab_dates(start_day:end_day);
small_iso_dates = large_iso_dates(start_day:end_day);

%Gets Projection information from datafile
mapprojection = h5readatt(file_path, '/Grid', 'mapprojection');
angleunits = h5readatt(file_path, '/Grid', 'angleunits');
aspect = h5readatt(file_path, '/Grid', 'aspect');
falsenorthing = h5readatt(file_path, '/Grid', 'falsenorthing');
falseeasting = h5readatt(file_path, '/Grid', 'falseeasting');
geoid = h5readatt(file_path, '/Grid', 'geoid');
maplatlimit = h5readatt(file_path, '/Grid', 'maplatlimit');
maplonlimit = h5readatt(file_path, '/Grid', 'maplonlimit');
mapparallels = h5readatt(file_path, '/Grid', 'mapparallels');
nparallels = h5readatt(file_path, '/Grid', 'nparallels');
origin = h5readatt(file_path, '/Grid', 'origin');
scalefactor = h5readatt(file_path, '/Grid', 'scalefactor');
trimlat = h5readatt(file_path, '/Grid', 'trimlat');
trimlon = h5readatt(file_path, '/Grid', 'trimlon');

%Write all these data and metadata to a new h5 file.  Its frustrating
%because matlab won't let you just copy the ATTR of one file into another.
h5_path = ['/Grid/' metavariable];
data_size = size(small_grid);

%creates and writes new data
h5create(save_file, h5_path, data_size);
h5write(save_file, h5_path, small_grid)

%adds dates to attributes
h5writeatt(save_file, '/', 'MATLABdates', small_matlab_dates)
h5writeatt(save_file, '/', 'ISOdates', small_matlab_dates)

%adds projection information from original data to new file
h5writeatt(file_path, '/', 'authors_note', 'These are the parameters taken from the original dataset');
h5writeatt(file_path, '/', 'mapprojection', mapprojection);
h5writeatt(file_path, '/', 'angleunits', angleunits);
h5writeatt(file_path, '/', 'aspect', aspect);
h5writeatt(file_path, '/', 'falsenorthing', falsenorthing);
h5writeatt(file_path, '/', 'falseeasting', falseeasting);
h5writeatt(file_path, '/', 'geoid', geoid);
h5writeatt(file_path, '/', 'maplatlimit', maplatlimit);
h5writeatt(file_path, '/', 'maplonlimit', maplonlimit);
h5writeatt(file_path, '/', 'mapparallels', mapparallels);
h5writeatt(file_path, '/', 'nparallels', nparallels);
h5writeatt(file_path, '/', 'origin', origin);
h5writeatt(file_path, '/', 'scalefactor', scalefactor);
h5writeatt(file_path, '/', 'trimlat', trimlat);
h5writeatt(file_path, '/', 'trimlon', trimlon);

% Now save the reference raster object parameters in h5 file (proj ->
% intrinsic)
h5writeatt(file_path, '/Grid', 'Raster_Authors_Note', 'This is the params of the Matlab Reference Raster Object used to subset these data');
h5writeatt(file_path, '/Grid', 'XWorldLimits', small_RefRaster.XWorldLimits);
h5writeatt(file_path, '/Grid', 'YWorldLimits', small_RefRaster.YWorldLimits);
h5writeatt(file_path, '/Grid', 'RasterSize', small_RefRaster.RasterSize);
h5writeatt(file_path, '/Grid', 'RasterInterpretation', small_RefRaster.RasterInterpretation);
h5writeatt(file_path, '/Grid', 'ColumnsStartFrom', small_RefRaster.ColumnsStartFrom);
h5writeatt(file_path, '/Grid', 'RowsStartFrom', small_RefRaster.RowsStartFrom);
h5writeatt(file_path, '/Grid', 'CellExtentInWorldX', small_RefRaster.CellExtentInWorldX);
h5writeatt(file_path, '/Grid', 'CellExtentInWorldY', small_RefRaster.CellExtentInWorldY);
h5writeatt(file_path, '/Grid', 'RasterExtentInWorldX', small_RefRaster.RasterExtentInWorldX);
h5writeatt(file_path, '/Grid', 'RasterExtentInWorldY', small_RefRaster.RasterExtentInWorldY);
h5writeatt(file_path, '/Grid', 'XIntrinsicLimits', small_RefRaster.XIntrinsicLimits);
h5writeatt(file_path, '/Grid', 'YIntrinsicLimits', small_RefRaster.YIntrinsicLimits);
h5writeatt(file_path, '/Grid', 'TransformationType', small_RefRaster.TransformationType);
h5writeatt(file_path, '/Grid', 'CoordinateSystemType', small_RefRaster.CoordinateSystemType);
h5writeatt(file_path, '/Grid', 'ProjectedCRS', small_RefRaster.ProjectedCRS);

% Now save used projection information in H5 File (lat_long -> projection
% coord)
h5writeatt(file_path, '/Grid', 'proj_authors_note', 'This is the matlab projection object params used to subset these data');
h5writeatt(file_path, '/Grid', 'proj_mapprojection', proj.mapprojection);
h5writeatt(file_path, '/Grid', 'proj_zone', proj.zone);
h5writeatt(file_path, '/Grid', 'proj_angleunits', proj.angleunits);
h5writeatt(file_path, '/Grid', 'proj_aspect', proj.aspect);
h5writeatt(file_path, '/Grid', 'proj_falsenorthing', proj.falsenorthing);
h5writeatt(file_path, '/Grid', 'proj_falseeasting', proj.falseeasting);
h5writeatt(file_path, '/Grid', 'proj_fixedorient', proj.fixedorient);
h5writeatt(file_path, '/Grid', 'proj_geoid', proj.geoid);
h5writeatt(file_path, '/Grid', 'proj_maplatlimit', proj.maplatlimit);
h5writeatt(file_path, '/Grid', 'proj_maplonlimit', proj.maplonlimit);
h5writeatt(file_path, '/Grid', 'proj_mapparallels', proj.mapparallels);
h5writeatt(file_path, '/Grid', 'proj_nparallels', proj.nparallels);
h5writeatt(file_path, '/Grid', 'proj_origin', proj.origin);
h5writeatt(file_path, '/Grid', 'proj_scalefactor', proj.scalefactor);
h5writeatt(file_path, '/Grid', 'proj_trimlat', proj.trimlat);
h5writeatt(file_path, '/Grid', 'proj_trimlon', proj.trimlon);
h5writeatt(file_path, '/Grid', 'proj_frame', proj.frame);
h5writeatt(file_path, '/Grid', 'proj_ffill', proj.ffill);
h5writeatt(file_path, '/Grid', 'proj_fedgecolor', proj.fedgecolor);
h5writeatt(file_path, '/Grid', 'proj_ffacecolor', proj.ffacecolor);
h5writeatt(file_path, '/Grid', 'proj_flatlimit', proj.flatlimit);
h5writeatt(file_path, '/Grid', 'proj_flinewidth', proj.flinewidth);
h5writeatt(file_path, '/Grid', 'proj_flonlimit', proj.flonlimit);
h5writeatt(file_path, '/Grid', 'proj_grid', proj.grid);
h5writeatt(file_path, '/Grid', 'proj_galtitude', proj.galtitude);
h5writeatt(file_path, '/Grid', 'proj_gcolor', proj.gcolor);
h5writeatt(file_path, '/Grid', 'proj_glinestyle', proj.glinestyle);
h5writeatt(file_path, '/Grid', 'proj_glinewidth', proj.glinewidth);
h5writeatt(file_path, '/Grid', 'proj_mlineexception', proj.mlineexception);
h5writeatt(file_path, '/Grid', 'proj_mlinefill', proj.mlinefill);
h5writeatt(file_path, '/Grid', 'proj_mlinelimit', proj.mlinelimit);
h5writeatt(file_path, '/Grid', 'proj_mlinelocation', proj.mlinelocation);
h5writeatt(file_path, '/Grid', 'proj_mlinevisible', proj.mlinevisible);
h5writeatt(file_path, '/Grid', 'proj_plineexception', proj.plineexception);
h5writeatt(file_path, '/Grid', 'proj_plinefill', proj.plinefill);
h5writeatt(file_path, '/Grid', 'proj_plinelimit', proj.plinelimit);
h5writeatt(file_path, '/Grid', 'proj_plinelocation', proj.plinelocation);
h5writeatt(file_path, '/Grid', 'proj_fontangle', proj.fontangle);
h5writeatt(file_path, '/Grid', 'proj_fontcolor', proj.fontcolor);
h5writeatt(file_path, '/Grid', 'proj_fontname', proj.fontname);
h5writeatt(file_path, '/Grid', 'proj_fontsize', proj.fontsize);
h5writeatt(file_path, '/Grid', 'proj_fontunits', proj.fontunits);
h5writeatt(file_path, '/Grid', 'proj_fontweight', proj.fontweight);
h5writeatt(file_path, '/Grid', 'proj_labelformat', proj.labelformat);
h5writeatt(file_path, '/Grid', 'proj_labelrotation', proj.labelrotation);
h5writeatt(file_path, '/Grid', 'proj_labelunits', proj.labelunits);
h5writeatt(file_path, '/Grid', 'proj_meridianlabel', proj.meridianlabel);
h5writeatt(file_path, '/Grid', 'proj_mlabellocation', proj.mlabellocation);
h5writeatt(file_path, '/Grid', 'proj_mlabelparallel', proj.mlabelparallel);
h5writeatt(file_path, '/Grid', 'proj_mlabelround', proj.mlabelround);
h5writeatt(file_path, '/Grid', 'proj_parallellabel', proj.parallellabel);
h5writeatt(file_path, '/Grid', 'proj_plabellocation', proj.plabellocation);
h5writeatt(file_path, '/Grid', 'proj_plabelmeridian', proj.plabelmeridian);
h5writeatt(file_path, '/Grid', 'proj_plabelround', proj.plabelround);