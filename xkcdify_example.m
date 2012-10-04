% This file contains a simple Matlab script that demonstrates how to use
% xkcdify.m  
%
% The most up to date version of this file can be found at
% https://github.com/slayton/matlab-xkcdify
%
% Copyright(c) 2012, Stuart P. Layton <stuart.layton@gmail.com>
% http://stuartlayton.com
%
% Revision History
%   2012/10/04 - Initial Release


%% - Example 1, XKCDify simple line plots
clear;
clc;
close all;

figure('Position', [100 460 1120 420]);
a(1) = subplot(121); a(2) = subplot(122);

x = 0:.05:2*pi;
y1 = zeros(size(x));  % flat line
y2 =  mod(round(x / pi),2)*1.5 - .75; % Square wave
y3 = .2 + .6 * sin(x); % sine wave

plot(x,y1,x,y2,x,y3, 'linewidth', 4, 'Parent', a(1));
plot(x,y1,x,y2,x,y3, 'linewidth', 4, 'Parent', a(2));
set(a, 'XLim', [x(1) - .25, x(end)+.25], 'YLim', [-.9 .9]);

xkcdify(a(2));

%% - Example 2, XKCDify a bar plot with a line plot on top
clear; close all; clc;

figure('Position', [100 460 1120 420]);
a(1) = subplot(121); a(2) = subplot(122);


x = [0:.1:5];
y = 1 + (x-2).^2;

bar([ 3 2 4 6], 'Parent', a(1));
line(x,y,'Color', 'r', 'lineWidth', 3, 'Parent', a(1));
bar([ 3 2 4 6], 'Parent', a(2));
line(x,y,'Color', 'r', 'lineWidth', 3, 'Parent', a(2));


xkcdify(a(2));

set(a, 'XLim', [.5 4.5], 'YLim', [0 7]);

%% - Example 3, XKCDify a boxplot with a line plot on top
clear; close all; clc;
n = 5;  data = rand(20,n) * 5;
x = 1:n; y =  mean(data) + rand(1,n);

figure('Position', [100 460 1120 420]);
a(1) = subplot(121); a(2) = subplot(122);

boxplot( data, 'Parent', a(1)); 

set( get(get(a(1), 'Children'),'Children'), 'LineWidth', 3); % Hack to grow the line width of the boxplot
line(x, y, 'color', 'g', 'linewidth', 3, 'Parent', a(1));

boxplot( data, 'Parent', a(2)); 

set( get(get(a(2), 'Children'),'Children'), 'LineWidth', 3); % Hack to grow the line width of the boxplot
line(x, y, 'color', 'g', 'linewidth', 3, 'Parent', a(2));

xkcdify(gca)

%% - Example 4, XKCDify a subset of axes inside a figure

clear; close all; clc;
figure('Position', [100 460 1120 420]);
x = 0:.1: 2 * pi;
y1 = sin(x);
y2 = cos(x);

for i = 1:3
    a(i) = subplot(1,3,i);
    
    plot(x * i, sin(x ./ (i/2)), x*i, cos(x ./ (i/2)), 'Parent', a(i), 'linewidth', 4);
    set(a(i), 'XLim', [x(1) - .25, x(end)+.25] * i, 'YLim', [-1.2 1.2]);
end
xkcdify(a(2:3))




