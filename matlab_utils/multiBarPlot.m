function multiBarPlot(values, headings, yvals, x_labels, y_label,lettersize, color )
%create a bar graph with as many bars as entries in Values
%   x_Labels = cells with names for x-axis
%   values = cells: number subplots, within each cell:  columns for each bar, rows are single values within each bar
%   heading = cells with strings in order of values
%   y_label = string
%   lettersize integer defining the size of x axis labels
%   color = RGB values for color of the bars, e.g. [.8 .8 .8]
%
%   MR 2017



nrPlots = length(values);
if nrPlots < 5
    rows = 1; % number rows of subplots
elseif nrPlots < 9
    rows = 3;
else
    rows = 3;
end

columns = nrPlots/rows; % number of columns in plot
columns = ceil(columns);



figure('color',[1 1 1]);

for i = 1:length(values)
    f(i) = subplot(rows,columns,i)
    h = bar(nanmean(values{i}),0.5);
    set(h(1),'FaceColor',color)
    hold on
    % create SEs
    for ind = 1:size(values{i},2)
        SE(ind) = nanstd(values{i}(:,ind)/sqrt(size(values{i}(:,1),1)));
    end
    errorbar(nanmean(values{i}),SE , 'k', 'linestyle', 'none', 'linewidth', 1.5);
    ax = gca;
    ax.XTickLabel = x_labels;
    ax.FontSize = lettersize;
    ax.YLim = yvals;
    ax.XLim = [0 size(values{i},2)+1];
    ylength(i) = ax.YLim(2);
    
    if(size(values{i},2)>6)
    ax.XTickLabelRotation=33;
    end
    %lh = legend('LH','RH');
    %set(lh,'Location','BestOutside','Orientation','horizontal')
    ylabel(y_label)
    t = title(headings{i})
    set(t, 'Interpreter', 'none')
    box off;
end
linkaxes(f,'xy')
end

