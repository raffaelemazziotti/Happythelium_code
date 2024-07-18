function [raw, lbl, props] = rpe_preproc(pathToimg)
    
    nColors = 2; % bd and lines
    l = 5; % structuring element

    if nargin<2
        cutoff=500;
    end

    raw = imread(pathToimg);

    green = raw(:,:,2);
    level = multithresh(green);
    green=imbinarize(green,'adaptive','ForegroundPolarity','dark','Sensitivity',0.6);
    se = strel('disk',9);
    blobs = imopen(green,se); % blobs identification
    green = bwareaopen(green,1000);
    green = repmat(green,1,1,3);
    blobs = repmat(blobs,1,1,3);
    raw(green~=1)=0;
    raw(blobs==1)=0;

    sz = size(raw);
    imgflat = single( reshape(raw,prod(sz(1:2)),3) );
    idx = kmeans(imgflat,nColors);
    grps = reshape(idx,sz(1),sz(2));
    [a,bg] = max(histc(grps(:),unique(grps(:))));
    grps = grps==bg;

    se90 = strel('line',l,90);
    se0 = strel('line',l,0);
    se45 = strel('line',l,45);
    se135 = strel('line',l,45);
    sei45 = strel('line',l,-45);

    grps = ~imdilate(~grps,se90);
    grps = ~imdilate(~grps,se0);
    grps = ~imdilate(~grps,se45);
    grps = ~imdilate(~grps,sei45);
    grps = ~imdilate(~grps,se135);
    grps = bwareaopen(~grps,200);
    grps = bwmorph(grps,'skel',Inf);
    grps = bwareaopen(grps,200);
    grps = ~grps;
    [lbl,num] = bwlabel(grps,4);
    
    stats = regionprops(lbl,'Area','Centroid','Eccentricity','Orientation','Perimeter');
    xy=cell2mat({stats.Centroid}');
    Area = cell2mat({stats.Area}');
    Perimeter = cell2mat({stats.Perimeter}');
    Eccentricity = cell2mat({stats.Eccentricity}');
    Orientation = cell2mat({stats.Orientation}');
    Circularity= (4.*Area.*pi)./(Perimeter.^2);
    x = xy(:,1);
    y = xy(:,2);
    props = table(x,y,Area,Perimeter,Eccentricity,Orientation,Circularity);
    props = props(props.Area>cutoff,:);
end

