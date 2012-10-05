# XKCDIFY

XKCDIFY is tool for converting most matlab plot to XKCD style plots!

XKCDIFY was designed to work in conjunction with the standard Matlab plotting utilities, making it compatible
with most matlab code. Simply create plot as you would with any of the standard 2D plotting tools and when you 
satisfied you can then XKCDIFY them.

XKCDIFY works by iterating over the children of an axes and distorts the individual children based upon their TYPE.
Currently only children of type LINE or PATCH get distorted. Additionally if the child type is HGGROUP then XKCDIFY
iterates on the sub-children of the hggroup.

## Example Code

#### Simple Line Plots
```matlab
figure('Position', [100 460 1120 420]);
a(1) = subplot(121); a(2) = subplot(122);

x = 0:.05:2*pi;
y1 = zeros(size(x));  % flat line
y2 =  mod(round(x / pi),2)*1.5 - .75; % Square wave
y3 = .2 + .6 * sin(x); % sine wave

plot(x,y1,x,y2,x,y3, 'linewidth', 4, 'Parent', a(1));
plot(x,y1,x,y2,x,y3, 'linewidth', 4, 'Parent', a(2));
set(a, 'XLim', [x(1) - .25, x(end)+.25], 'YLim', [-.9 .9]);
```
![Regular and XKCDIFY Line Plots](https://raw.github.com/slayton/matlab-xkcdify/master/line_example.png)