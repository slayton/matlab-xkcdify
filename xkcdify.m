function xkcdify(axesList, renderAxesLines)
%XKCDIFY redraw an existing axes in an XKCD style
%
%   XKCDIFY( AXES ) re-renders all childen of AXES to have a hand drawn
%   XKCD style, http://xkcd.com, AXES can be a single axes or a vector of axes
%
%   NOTE: Only plots of type LINE and PATCH are re-rendered. This should 
%   be sufficient for the majority of 2d plots such as:
%       - plot
%       - bar
%       - boxplot
%       - etc...
%
%   NOTE: This function does not alter the actual style of the axes
%   themselves, that functionality will be added in the next version.  I
%   still have to figure out the best way to do this, if you have a
%   suggestion please email me!
%
%   Finally the most up to date version of this code can be found at:
%   https://github.com/slayton/matlab-xkcdify
%
% Copyright(c) 2012, Stuart P. Layton <stuart.layton@gmail.com> MIT
% http://stuartlayton.com

% Revision History
%   2012/10/04 - Initial Release

    
    if nargin==0
        error('axHandle must be specified');
    elseif ~all( ishandle(axesList) )
        error('axHandle must be a valid axes handle');
    elseif ~all( strcmp( get(axesList, 'type'), 'axes') )
        error('axHandle must be a valid axes handle');
    end
    
    if nargin==1
        renderAxesLines = 0;
    end
    
    for axN = 1:numel(axesList)
        axHandle = axesList(axN);

        pixPerX = [];
        pixPerY = [];
   
        axChildren = get(axHandle, 'Children');
        operareOnChildren(axChildren, axHandle);
    
        if renderAxesLines == 1
            renderNewAxesLine(axHandle)
        end
        
    end

    
    
function renderNewAxesLine(ax)
    
    nPixOffset = 15;
    
    isBoxOn = strcmp( get(ax,'Box'), 'on' );
    set(ax,'Box', 'off');
    % Get the correct location for the next axes
    pos = getAxesPositionInUnits(ax,'Pixels');
    pos(1:2) = pos(1:2) - nPixOffset;

    if isBoxOn
        pos(3:4) = pos(3:4) + nPixOffset*2;
    else
        pos(3:4) = pos(3:4) + nPixOffset;
    end
    
    
    newAxes = axes('Units', 'pixels', 'Position', pos, 'Color', 'none');
    set(newAxes,'Units', get(ax,'Units'), 'XTick', [], 'YTick', []);
   
    
    [px py] = getPixelsPerUnitForAxes(newAxes);
    dx = nPixOffset / px;
    dy = nPixOffset / py;      
    
    xlim = get(newAxes,'XLim');
    ylim = get(newAxes, 'YLim');

    
    axArgs = {'Parent', newAxes, 'Color', 'k', 'LineWidth', 4};
    axLine(1) = line( [dx dx], ylim + [dy -dy], axArgs{:});
    axLine(2) = line( xlim + [dx -dx], [dy dy], axArgs{:});
    
    %if 'Box' is on then draw the top and right edges of thea axes
    if isBoxOn
        axLine(3) = line( xlim(2) - [dx dx] + .00001, ylim + [dy -dy], axArgs{:});
        axLine(4) = line( xlim + [dx -dx], ylim(2) - [dy dy] + .00001,  axArgs{:});
    end
    
    axis(newAxes, 'off');
    for i = 1:numel(axLine)
        cartoonifyAxesEdge(axLine(i), newAxes);
    end
      
    set(ax, 'FontName', 'Comic Sans MS', 'FontSize', 14);
    
   
end


function operareOnChildren(C, ax)

    % iterate on the individual children but in reverse order
    % also ensure that C is treated as a row vector
    
    for c = fliplr( C(:)' )
    %for i = 1:nCh
        % we want to 
     %   c = C(nCh - i + 1);
        cType = get(c,'Type');
                
        switch cType
            case 'line'
                cartoonifyLine(c, ax);
                uistack(c,'top');

            case 'patch'
                cartoonifyPatch(c, ax);
                uistack(c,'top');
 
            case 'hggroup'              
                % if not a line or patch operate on the children of the
                % hggroup child, plot-ception!
                operareOnChildren( get(c,'Children'), ax); 
                uistack(c,'top');
            otherwise
                warning('Received unsupportd child of type %s', cType);
        end        
    end
    
end

function cartoonifyLine(l,  ax)
    
    if nargin==2
        addMask = 1;
    end

    xpts = get(l, 'XData')';
    ypts = get(l, 'YData')';

    %only jitter lines with more than 1 point   
    if numel(xpts)>1 

        [pixPerX, pixPerY] = getPixelsPerUnitForAxes(ax);
 
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
        
        [xpts, ypts] = upSampleAndJitter(xpts, ypts, xJitter, yJitter);
               
    end
    
    set(l, 'XData', xpts , 'YData', ypts, 'linestyle', '-');
    
    
    addBackgroundMask(xpts, ypts, get(l, 'LineWidth') * 3, ax);


    
end

function cartoonifyAxesEdge(l, ax)
    
    xpts = get(l, 'XData')';
    ypts = get(l, 'YData')';

    %only jitter lines with more than 1 point   
    if numel(xpts)>1 

        [pixPerX, pixPerY] = getPixelsPerUnitForAxes(ax);
 
        % I should figure out a better way to calculate this
        xJitter = 3 / pixPerX; 
        yJitter = 3 / pixPerY;

        if all( diff( ypts) == 0) 
            % if the line is horizontal don't jitter in X
            xJitter = 0;
        
        elseif all( diff( xpts) == 0)
            % if the line is veritcal don't jitter in y
            yJitter = 0;      
        end
        
        [xpts, ypts] = upSampleAndJitter(xpts, ypts, xJitter, yJitter);
               
    end
    
    set(l, 'XData', xpts , 'YData', ypts, 'linestyle', '-');    
end



function [x, y] = upSampleAndJitter(x, y, jx, jy, n)

    % we want to upsample the line to have a number of that is proportional
    % to the number of pixels the line occupies on the screen. Long lines
    % will get a lot of samples, short points will get a few
    
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

function addBackgroundMask(xpts, ypts, w, ax)
   
    bg = get(ax, 'color');
    line(xpts, ypts, 'linewidth', w, 'color', bg, 'Parent', ax);
    
end

function pos = getAxesPositionInUnits(ax, units)
    
    if strcmp( get( ax,'Units'), units )
        pos = get(ax,'Position');
        return;
    end
    % if the current axes contains a box plot then we need to create a
    % temporary axes as changing the units on a boxplot causes the
    % pos(4) to be set to 0
    axUserData = get(ax,'UserData');
    if ~isempty(axUserData) && iscell(axUserData) && strcmp(axUserData{1}, 'boxplot')
        axTemp = axes('Units','normalized','Position', get(ax,'Position'));
        set(axTemp,'Units', units);
        pos = get(axTemp,'position');
        delete(axTemp);
    else
        origUnits = get(ax,'Units');
        set(ax,'Units', 'pixels');
        pos = get(ax,'Position');
        set(ax,'Units', origUnits);
    end

    
end
function setAxesPositionInUnits(ax, pos, units)
    
    if strcmp( get( ax,'Units'), units )
        set(ax,'Position', pos);
        return;
    end
    
    % if the current axes contains a box plot then we need to create a
    % temporary axes as changing the units on a boxplot causes the
    % pos(4) to be set to 0
    axUserData = get(ax,'UserData');
    if ~isempty(axUserData) && iscell(axUserData) && strcmp(axUserData{1}, 'boxplot')
        axTemp = axes('Units', get(ax,'Units'), 'Position', get(ax,'Position'));
        origUnit = get(axTemp,'Units');
        set(axTemp,'Units', units);
        set(axTemp,'position', pos);
        set(axTemp, 'Units', origUnit);
        set(ax, 'Position', get(axTemp, 'Position') );
        delete(axTemp);
    else
        origUnits = get(ax,'Units');
        set(ax,'Units', units);
        set(ax,'Potision', pos);
        set(ax,'Units', origUnits);
    end
end

% Main function for converting units to pixels, refers to the main drawing
% axes
function [ppX ppY] = getPixelsPerUnit()

    if ~isempty(pixPerX) && ~ isempty(pixPerY)
        ppX = pixPerX;
        ppY = pixPerY;
        return;
    end
    [ppX ppY] = getPixelsPerUnitForAxes(axHandle);
end

% Worker function for converting units to pixels, can be used with any axes
% allowing it to be used with subsequently created axes that are involved
% in rendering the axes lines
function [px py] = getPixelsPerUnitForAxes(axH)
    %get the size of the current axes in pixels
    %get the lims of the current axes in plotting units
    %calculate the number of pixels per plotting unit
    pos = getAxesPositionInUnits(axH, 'Pixels');
   
    xLim = get(axH, 'XLim');
    yLim = get(axH, 'YLim');

    px = pos(3) ./ diff(xLim);
    py = pos(4) ./ diff(yLim);
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
function cartoonifyPatch(p, ax)
    
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
    cNew = [];
    for i = 1:nPatch
        %newVtx( end+1,:) = oldVtx( 1 + (i-1)*nOld , : );
        [x, y] = upSampleAndJitter(xPts(:,i), yPts(:,i), xJitter, yJitter, nNew);


        xNew(:,i) = x(:);
        yNew(:,i) = y(:);
        nNew = numel(x);
        
        if ~isempty(cData)
            cNew(:,i) = interp1( linspace( 0 , 1, nOld), cData(:,i), linspace(0, 1, nNew));
        end
     
        
        newVtx(end+1,1:2) = oldVtx( 1 + (i-1)*(nOld+1), 1:2);
        newVtxNorm( end+1, 1:3) = nan;
        

        % set the first and last vertex for each bar back in its original
        % position so everything lines up
        yNew([1, end], i) = yPts([1,end],i);
        xNew([1, end], i) = xPts([1,end],i);

      
        newVtx(end + (1:nNew), :) = [xNew(:,i), yNew(:,i)] ;
        t = repmat( oldVtxNorm( 1+1 + (i-1)*(nOld+1) , : ), nNew, 1);
        newVtxNorm( end+ (1 : nNew) , : ) = t;
        
        addBackgroundMask(xNew(:,i), yNew(:,i), 6, ax);
       
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
    %set(p, 'EdgeColor', 'none');
end


end