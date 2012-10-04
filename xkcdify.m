function xkcdify(axHandle)

    if nargin==0
        error('axHandle must be specified');
    end
    
    axCh = get(axHandle, 'Children');
 
    operate_on_children(axCh, axHandle);

end

function operate_on_children(C, ax)

    % iterate on the individual children but in reverse order
    % also ensure that C is treated as a row vector
    
    for c = fliplr( C(:)' )
    %for i = 1:nCh
        % we want to 
     %   c = C(nCh - i + 1);
        cType = get(c,'Type');
                
        switch cType
            case 'line'
                cartoonify_line(c, ax);
                uistack(c,'top');

            case 'patch'
                cartoonify_patch(c, ax);
                uistack(c,'top');

            case 'hggroup'              
                % if not a line or patch operate on the children of the
                % hggroup child, plot-ception!
                operate_on_children( get(c,'Children'), ax); 
                uistack(c,'top');
        end        
    end
    
end

function cartoonify_line(l,  ax)

    xpts = get(l, 'XData')';
    ypts = get(l, 'YData')';

    %only jitter lines with more than 1 point   
    if numel(xpts)>1 
 
        [pixPerX, pixPerY] = getPixelsPerUnit();
 
        % I should figure out a better way to calculate this
        xJitter = 6 / pixPerX; 
        yJitter = 6 / pixPerY;

        if all( diff( ypts) == 0) 
            % if the line is horizontal don't jitter in X
            xJitter = 0;
        
        elseif all( diff( xpts) == 0)
            % if the line is veritcal don't jitter in y
            yJitter = 0;      
        end
        
        [xpts, ypts] = up_sample_and_jitter(xpts, ypts, xJitter, yJitter);
               
    end
    
    set(l, 'XData', xpts , 'YData', ypts, 'linestyle', '-');
    
    add_background_mask(xpts, ypts, get(l, 'LineWidth') * 3, ax);

    
end



function [x, y] = up_sample_and_jitter(x, y, jx, jy, n)

    % we want to upsample the line to have a number of that is proportional
    % to the number of pixels the line occupies on the screen. Long lines
    % will get a lot of samples, short points will get a few
    
    if nargin == 4 || n == 0
        n = getLineLength(x,y);  
        ptsPerPix = 1/4;
        n = ceil( n * ptsPerPix);
    end
  
%     n = max(numel(x), n); % don't down sample, only up sample!
    
    x = interp1( linspace(0, 1, numel(x)) , x, linspace(0, 1, n) );
    y = interp1( linspace(0, 1, numel(y)) , y, linspace(0, 1, n) );
    
    
    x = x + smooth( generateNoise(n) .* rand(n,1) .* jx )';
    y = y + smooth( generateNoise(n) .* rand(n,1) .* jy )';

end

function noise = generateNoise(n)
    noise = zeros(n,1);
    
    iStart = ceil(n/50);
    iEnd = n - iStart;
    
    i = iStart;
    while i < iEnd
        if randi(10,1,1) < 2
            
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

function add_background_mask(xpts, ypts, w, ax)
   
    bg = get(ax, 'color');
    line(xpts, ypts, 'linewidth', w, 'color', bg);
    
end

function [pixPerX, pixPerY] = getPixelsPerUnit()

    %get the size of the current axes in pixels
    %get the lims of the current axes in plotting units
    %calculate the number of pixels per plotting unit
    
    ax = gca;
    pixData = get(gcf,'UserData');
    if isempty(pixData) || ~isstruct(pixData)
        
        % if the current axes contains a box plot then we need to create a
        % temporary axes as changing the units on a boxplot causes the
        % pos(4) to be set to 0
        axUserData = get(gca,'UserData');
        if ~isempty(axUserData) && iscell(axUserData) && strcmp(axUserData{1}, 'boxplot')
            axTemp = axes('Units','normalized','Position', get(ax,'Position'));
            set(axTemp,'Units', 'pixels');
            pos = get(axTemp,'position');
            delete(axTemp);
        else
            units = get(gca,'Units');
            set(gca,'Units', 'pixels');
            pos = get(gca,'Position');
            set(gca,'Units', units);
        end
       
        
        xLim = get(gca, 'XLim');
        yLim = get(gca, 'YLim');
       
        pixData.pixPerX = pos(3) ./ diff(xLim);
        pixData.pixPerY = pos(4) ./ diff(yLim);
        
        % store the pixData struct in the figure so we can reference it
        % later. Ideally we would need to store this in the AXES but
        % because boxplot stores data there we can't store it there.
        set(gcf,'UserData', pixData);
    end
    
    pixPerX = pixData.pixPerX;
    pixPerY = pixData.pixPerY;
    
end

function [ len ] = getLineLength(x, y)

    % convert x and y to pixels from units
    [pixPerX, pixPerY] = getPixelsPerUnit();
    x = x(:) * pixPerX; 
    y = y(:) * pixPerY;
    
    %compute the length of the line
    len = sum( sqrt( diff( x ).^2 + diff( y ).^2 ) );    
end


function v = smooth(v)
    % these values are pretty arbitrary, i should probably come up with a
    % better way to calculate them from the data
    
    a = 1/2;
    nPad = 10;
    % filter the yValues to smooth the jitter
    v = filtfilt(a, [1 a-1], [ ones(nPad ,1) * v(1); v; ones(nPad,1) * v(end) ]);
    v = filtfilt(a, [1 a-1], v);
    v = v(nPad+1:end-nPad);   
    v = v(:);

end

% This method is by far the buggiest part of the script. It appears to work,
% however it fails to retain the original color of the patch, and sets it to
% blue.  This doesn't prevent the user from reseting the color after the
% fact using set(barHandle, 'FaceColor', color) which IMHO is an acceptable
% workaround
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

    
    nNew = 0;
    for i = 1:nPatch
        %newVtx( end+1,:) = oldVtx( 1 + (i-1)*nOld , : );
        [x, y] = up_sample_and_jitter(xPts(:,i), yPts(:,i), xJitter, yJitter, nNew);


        xNew(:,i) = x(:);
        yNew(:,i) = y(:);
        nNew = numel(x);
        
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
        
        add_background_mask(xNew(:,i), yNew(:,i), 6, ax);
       
    end
    
    newVtx(end+1, :) = oldVtx(end,:);
    newVtxNorm(end+1, : ) = nan;
    
    
    % construct the new vertex data
    newFaces = true(size(newVtx,1),1);
    newFaces(1:nNew+1:end) = false;
    newFaces = find(newFaces);
    newFaces = reshape(newFaces, nNew, nPatch)';
    
    % I can't seem to get this working correct, so I'll set the color to
    % the default matlab blue not the same as 'color', 'blue'!
    newFaceVtxCData = [ 0 0 .5608 ];
      
    set(p, 'CData', cNew, 'FaceVertexCData', newFaceVtxCData, 'Faces', newFaces,  ...
        'Vertices', newVtx, 'XData', xNew, 'YData', yNew, 'VertexNormals', newVtxNorm);
    set(p, 'EdgeColor', 'none');
end