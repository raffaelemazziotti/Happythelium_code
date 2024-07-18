function [raw, lbl, props] = rpe_preproc(pathToimg)
    % Number of colors for k-means clustering
    nColors = 2; % bd and lines
    % Structuring element size
    l = 5; % structuring element

    % Default cutoff value if not provided
    if nargin<2
        cutoff=500;
    end

    % Read the image from the given path
    raw = imread(pathToimg);

    % Extract the green channel
    green = raw(:,:,2);
    % Multilevel thresholding
    level = multithresh(green);
    % Binarize the green channel using adaptive thresholding
    green=imbinarize(green,'adaptive','ForegroundPolarity','dark','Sensitivity',0.6);
    % Create a structuring element
    se = strel('disk',9);
    % Perform morphological opening to identify blobs
    blobs = imopen(green,se);
    % Remove small objects from the binary image
    green = bwareaopen(green,1000);
    % Replicate the binary mask to match the color image dimensions
    green = repmat(green,1,1,3);
    blobs = repmat(blobs,1,1,3);
    % Zero out the green and blob areas in the raw image
    raw(green~=1)=0;
    raw(blobs==1)=0;

    % Reshape the image for k-means clustering
    sz = size(raw);
    imgflat = single(reshape(raw,prod(sz(1:2)),3));
    % Perform k-means clustering
    idx = kmeans(imgflat,nColors);
    % Reshape the clustered index to match the image dimensions
    grps = reshape(idx,sz(1),sz(2));
    % Identify the background group
    [a,bg] = max(histc(grps(:),unique(grps(:))));
    grps = grps==bg;

    % Create line structuring elements for dilation
    se90 = strel('line',l,90);
    se0 = strel('line',l,0);
    se45 = strel('line',l,45);
    se135 = strel('line',l,45);
    sei45 = strel('line',l,-45);

    % Dilate the image using various line structuring elements
    grps = ~imdilate(~grps,se90);
    grps = ~imdilate(~grps,se0);
    grps = ~imdilate(~grps,se45);
    grps = ~imdilate(~grps,sei45);
    grps = ~imdilate(~grps,se135);
    % Remove small objects from the binary image
    grps = bwareaopen(~grps,200);
    % Skeletonize the binary image
    grps = bwmorph(grps,'skel',Inf);
    % Remove small objects from the binary skeleton
    grps = bwareaopen(grps,200);
    % Invert the binary image
    grps = ~grps;
    % Label connected components in the binary image
    [lbl,num] = bwlabel(grps,4);
    
    % Measure properties of image regions
    stats = regionprops(lbl,'Area','Centroid','Eccentricity','Orientation','Perimeter');
    % Extract properties into arrays
    xy=cell2mat({stats.Centroid}');
    Area = cell2mat({stats.Area}');
    Perimeter = cell2mat({stats.Perimeter}');
    Eccentricity = cell2mat({stats.Eccentricity}');
    Orientation = cell2mat({stats.Orientation}');
    Circularity= (4.*Area.*pi)./(Perimeter.^2);
    x = xy(:,1);
    y = xy(:,2);
    % Create a table of the properties
    props = table(x,y,Area,Perimeter,Eccentricity,Orientation,Circularity);
    % Filter the properties based on the area cutoff
    props = props(props.Area>cutoff,:);
end
