function xkcdify(axHandle)

    axCh = get(axHandle, 'Children');
   
    % operate on the axChildren
    operate_on_children(axCh, axHandle);

end

function operate_on_children(C, ax)

    nCh = numel(C);
    
    for i = 1:nCh
        
        c = C(i);
        cType = get(c,'Type');
                
        switch cType
            case 'line'
                cartoonify_line(c, ax);
                uistack(c,'top');

            case 'patch'
                cartoonify_patch(c, ax);
                uistack(c,'top');

            case 'hggroup'                
                operate_on_children( get(c,'Children'), ax); 
                uistack(c,'top');

        end        
    end
    
end

function cartoonify_line(l,  ax)

    xpts = get(l, 'XData');
    ypts = get(l, 'YData');
    xpts = xpts(:);
    ypts = ypts(:);
    
    
    if numel(xpts)>1 
 
        [pixPerX, pixPerY] = getPixelsPerUnit();
 
        xJitter = 6 / pixPerX;
        yJitter = 6 / pixPerY;

        if all( diff( xpts) == 0) 
            xJitter = 0;
        elseif all( diff( ypts) == 0)
            yJitter = 0;      
        end
        
        [xpts, ypts] = up_sample_and_jitter(xpts, ypts, xJitter, yJitter);
               
    end
    
    set(l, 'XData', xpts , 'YData', ypts, 'linestyle', '-');
    
    add_line_background_mask(xpts, ypts, get(l, 'LineWidth') * 3, ax);

    
end



function [x, y] = up_sample_and_jitter(x, y, jx, jy, n)

    if nargin == 4 || n == 0
        
        n = getLineLength(x,y);  
        ptsPerPix = 1/4;
        n = ceil( n * ptsPerPix);
    end
  
    
    x = interp1( linspace(0, 1, numel(x)) , x, linspace(0, 1, n) );
    y = interp1( linspace(0, 1, numel(y)) , y, linspace(0, 1, n) );
    
    
    x = x + smooth( generateNoise(n) .* rand(n,1) .* jx )';
    y = y + smooth( generateNoise(n) .* rand(n,1) .* jy )';

end

function noise = generateNoise(n)
    noise = zeros(n,1);
    
    iStart = ceil(n/20);
    iEnd = n - iStart;
    
    i = iStart;
    while i < iEnd
        if randi(30,1,1) < 2
            
            upDown = randsample([-1 1], 1);
            
            maxDur = max( min(iEnd - i, 100), 1);
            duration = randi( maxDur , 1, 1);
            noise(i:i+duration) = upDown;
            i = i + duration;
        end    
        i = i +1;
    end
    noise = noise(:);
end

function add_line_background_mask(xpts, ypts, w, ax)
   
    bg = get(ax, 'color');
    line(xpts, ypts, 'linewidth', w, 'color', bg);
    
end

function [pixPerX, pixPerY] = getPixelsPerUnit()

    ax = gca;
    pixData = get(gcf,'UserData');
    if isempty(pixData) || ~isstruct(pixData)

        axTemp = axes('Units','normalized','Position', get(ax,'Position'));
        set(axTemp,'Units', 'pixels');
        pos = get(axTemp,'position');
        delete(axTemp);
        
        xLim = get(gca, 'XLim');
        yLim = get(gca, 'YLim');
       
        pixData.pixPerX = pos(3) ./ diff(xLim);
        pixData.pixPerY = pos(4) ./ diff(yLim);
        
       
        set(gcf,'UserData', pixData);
    end
    
    pixPerX = pixData.pixPerX;
    pixPerY = pixData.pixPerY;
    
end

function [ len ] = getLineLength(x, y)

    [pixPerX, pixPerY] = getPixelsPerUnit();
    x = x * pixPerX;
    y = y * pixPerY;
    %compute the length of the line
    len=[ 0; cumsum(sqrt(diff(x(:)).^2 + diff(y(:)).^2))];

    
    %grab the last value
    len = len(end);
    
end


function v = smooth(v)
    a = 1/2;
    nPad = 10;
    % filter the yValues to smooth the jitter
    v = filtfilt(a, [1 a-1], [ ones(nPad ,1) * v(1); v; ones(nPad,1) * v(end) ]);
    v = filtfilt(a, [1 a-1], v);
    v = v(nPad+1:end-nPad);   
    v = v(:);

end

function cartoonify_patch(p, ax)
    
    xPts = get(p, 'XData');
    yPts = get(p, 'YData');
    cData = get(p, 'CData');
    
    nOld = size(xPts,1);
    
    xNew = [];
    yNew = [];
    cNew = [];
    
    oldVtx = get(p, 'Vertices');
    oldVtxNorm = get(p, 'VertexNormals');
    
    nPatch = size(xPts, 2);
    nVtx  = size(oldVtx,1);
    
    newVtx = [];
    newVtxNorm = [];
    
    [pixPerX, pixPerY] = getPixelsPerUnit();
 
    xJitter = 6 / pixPerX;
    yJitter = 6 / pixPerY;

    
    nNew = 0
    for i = 1:nPatch
        %newVtx( end+1,:) = oldVtx( 1 + (i-1)*nOld , : );
        nNew
        [x, y] = up_sample_and_jitter(xPts(:,i), yPts(:,i), xJitter, yJitter, nNew);
        size(xNew)
        size(x)

        xNew(:,i) = x(:);
        yNew(:,i) = y(:);
        nNew = numel(x)
        
        cNew(:,i) = interp1( linspace( 0 , 1, nOld), cData(:,i), linspace(0, 1, nNew));
     
        
        newVtx(end+1,1:2) = oldVtx( 1 + (i-1)*(nOld+1), 1:2);
        newVtxNorm( end+1, 1:3) = nan;
        

        % set the first and last vertex for each bar back in its original
        % position so everything lines up
        yNew([1, end], i) = yPts([1,end],i);
        xNew([1, end], i) = xPts([1,end],i);

      
        newVtx(end + (1:nNew), :) = [xNew(:,i), yNew(:,i)] ;
        t = repmat( oldVtxNorm( 1+1 + (i-1)*(nOld+1) , : ), nNew, 1);
        newVtxNorm( end+ (1 : nNew) , : ) = t;
        
        add_line_background_mask(xNew(:,i), yNew(:,i), 6, ax);
       
    end
    
    newVtx(end+1, :) = oldVtx(end,:);
    newVtxNorm(end+1, : ) = nan;
    
    
    % construct the new vertex data
    newFaces = true(size(newVtx,1),1);
    newFaces(1:nNew+1:end) = false;
    newFaces = find(newFaces);
    newFaces = reshape(newFaces, nNew, nPatch)';
    
    newFaceVtxCData = [ 0 0 .75 ];%b';%ones( size(newVtx,1) , 1);
    %newFaceVtxCData(end) = 2;
    
    set(p, 'CData', cNew, 'FaceVertexCData', newFaceVtxCData, 'Faces', newFaces,  ...
        'Vertices', newVtx, 'XData', xNew, 'YData', yNew, 'VertexNormals', newVtxNorm);
    set(p, 'EdgeColor', 'none');
end