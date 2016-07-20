% @brief this script merges n different CSV files with possibly different time
% basis into a single file with the same time basis.
% @author Martin Becker
% @date 2016-07-20
clear all; close all; clc

csv_dir = 'rawdata/2016-07-19_4/';
%csv_files = { 'AccX.csv', 'AccY.csv', 'AccZ.csv', 'GyrX.csv', 'GyrY.csv', 'GyrZ.csv', 'Press.csv', 'Temp.csv', 'Alt.csv', 'Lat.csv', 'Lng.csv', 'NSats.csv','Spd.csv'}; outfile = [csv_dir 'rawdata.csv'];
csv_files = { 'Roll.csv', 'Pitch.csv', 'Yaw.csv'}; outfile = [csv_dir 'reference.csv'];
STEP=0.02; % target dt in seconds

nfiles = numel (csv_files);

%% 1. read in all CSV
data = cell(1,nfiles);
label = cell(1,nfiles);
for k = 1 : nfiles
    fname = [csv_dir csv_files{k}];
    disp(['file=' fname]);
    fid = fopen (fname);
    head =  textscan(fid, '%s%s', 1, 'delimiter',',');
    lbl = deblank(cell2mat(head{2}));
    % clean headers a bit
    if lbl(1) == '#'
        lbl = lbl (2:end);
    end;
    % check if units are given. If so, strip
    pos = strfind (lbl, '[');
    if ~isempty(pos)
        lbl = lbl (1:pos(1)-1);
    end
    label{k} = lbl;
    fclose (fid);    
    data{k} = csvread(fname, 1);
end

%% 2. find common time line
allmi = -Inf;
allma = Inf;
for k=1:nfiles
    mi = min (data {k}(:,1));
    ma = max (data {k}(:,1));
    if mi > allmi 
        allmi = mi;
    end
    if ma < allma
        allma = ma;
    end
end
disp(['time range: ' num2str(allmi) ' .. ' num2str(allma)]);
ts = allmi : STEP : allma;
nsteps = numel(ts);

%% 3. interpolate all to common time line
newdata = zeros(nsteps, nfiles);
for k=1:nfiles
    samples = timeseries(data{k}(:,2), data{k}(:,1));    
    newsamples = resample(samples, ts); 
    newdata(:,k) = newsamples.data;
end

%% 4. plot
%col=hsv(nfiles);
%for k=1:nfiles
%    plot (ts, newdata(:,k), 'color',col(k,:)); hold on;    
%end ;
%legend(label)

%% 5. write result to csv
% make header
hdr=['time'];
for k=1:nfiles      
    hdr = [hdr ';' label{k}];
end 
hdr = [hdr '\n']
fid = fopen(outfile, 'w');
fprintf(fid, hdr);
fclose(fid);

dlmwrite(outfile, [ts' newdata], '-append', 'precision', '%.6f', 'delimiter', ';');