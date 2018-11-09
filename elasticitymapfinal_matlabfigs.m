clear all

%function[minElasticity, maxElasticity] = elasticitymap2;
%% this should map the elastic moduli for a certain indentation depth to
%% the positions were the measurements where taken

%% determine files to open
[FileName,PathName,FilterIndex] = uigetfile('*.mat','Resultsfiles',...
    'MultiSelect','on');

% Only when number of files exceeds Matlab's capacities (~600): 
% [FileName2,PathName2,FilterIndex2] = uigetfile('*.mat','Resultsfiles','MultiSelect','on');
% FileName=[FileName FileName2];

q = iscell(FileName);
if (q == 0)
    FileName = {FileName};
end
[w,NumberOfFiles] =  size(FileName);
% loop over all files
filelist = [];
for i = 1:NumberOfFiles
    filename = [PathName FileName{i}];
    filelist = [filelist; filename];
end


for i =1:NumberOfFiles
    found_match='not found';
    load(filelist(i,:));
    fileString = filelist(i, end-11:end-4);
end



[Labbook_file,Labbook_path] = uigetfile('*.txt','Labbookfile',...
    PathName,'MultiSelect','off');
LabbookFileName = [Labbook_path Labbook_file];

%% Plot for maximum indentation?
BigindentationDepth = 'y';input('Do you want a plot for maximum indentation? [y/n]>>>','s');

%% select the indentation depth, at which the map should be done
%intervals = input('For which indentation do you want to analyze?\nPlease give a vector of the form [indent1 indent2 etc.]\nThe values should be in micrometers.\nTo resume without binning press return\nNOTE: Differences in subsequent indentations should be large\nto allow every measurement to contribute to each bin\n>>>');
indentationDepth = input('For which intermediate indentation in micrometers do you want the map? \nPlease give a vector of the form [indent1 indent2 etc.]>>>');%[2 2.5 3 3.5 4 4.5 5 5.5 6 6.5 7];%
indentationDepth = indentationDepth * 1E-6;
if strcmp(BigindentationDepth,'y')==1
   indentationDepth(length(indentationDepth)+1) = 201187;
end

%% get maximum acceptable error for the indentation
ErrorIndentationDepth =input('What is the maximum acceptable error for the indentation in micrometers?>>>');% 0.5;%
ErrorIndentationDepth = ErrorIndentationDepth * 1E-6;

%% get Resolution of the measurement
measurementResolution = input('What was the measurement Resolution in micrometers?>>>');%50;%
measurementResolution = measurementResolution * 1E-6;

%% Scaling of the Plot
EndpointforPlot = input('Should the Plot be scaled by the maximum of the Elasticity values in all mapps combined? [yy/n] \n Or should the Plot be scaled by the maximum of the Elasticity values of each map? [y/n]>>>','s');%'n';%

if strcmp(EndpointforPlot,'n')==1
   ENDE = input('What should the maximum value be on the scale (in Pa)?>>>');%300;%
end
%% read Labbook file (may disappear if file contents are passed on to the
%% function)
openLabbook = fopen(LabbookFileName);
Labbook = textscan (openLabbook, '%s %f %f %f');
fclose(openLabbook);

%% correct Labbook contents to microns and for invertedness and split to
%% individual vectors
TimeStamp_check = Labbook{1,1};
TimeStamps = [];
stageY = [];
stageX = [];
height = [];
for q = 1:length(TimeStamp_check)
    if not(strcmp(TimeStamp_check(q),'0'))
        TimeStamps = [TimeStamps; TimeStamp_check(q)];
        stageY     = [stageY; Labbook{1,2}(q)];
        stageX     = [stageX; Labbook{1,3}(q)];
        %height     = [height; Labbook{1,4}(q)];
    end
end
%stageX = stageX *1E-6
stageY = stageY *-1
%minHeight = min(height);

%% compare TimeStamps in Labbook and filename, if equal, get first
%% datapoint smaller than specified indentation and put in a vector
elasticityData = zeros(length(TimeStamps),length(indentationDepth));
elasticityData(:,:) = NaN;
CounterOO(1:length(indentationDepth))=0;
CounterOOO(1:length(indentationDepth))=0;

for j = 1:length(indentationDepth)
for i =1:NumberOfFiles
% %     found_match='not found';
    load(filelist(i,:));
    fileString = filelist(i, end-11:end-4);
% %     RESULT_SIZE = size(RESULTS);
    for q = 1:length(TimeStamps)
        compareString = strcmp(fileString,TimeStamps(q));
        if compareString == 1
            if indentationDepth(j)==201187
                elasticityData(q,j) = RESULTS(1,3); 
            else
% %                 found_match = 'found';
                %dataPointIndex = find((RESULTS(:,1) <= indentationDepth(j)+ErrorIndentationDepth),1)
                dataPointIndex2 = find((RESULTS(:,1) <= indentationDepth(j)+ErrorIndentationDepth));
                dataPointIndex3 = find((RESULTS(:,1) >= indentationDepth(j)-ErrorIndentationDepth));
                dataPointIndex4 = intersect(dataPointIndex3,dataPointIndex2);
                [minumumvalue dataPointIndex5] = min(abs(RESULTS(dataPointIndex4,1)-indentationDepth(j)));  
% %                     dataPointIndex2
% %                     dataPointIndex3
% %                     dataPointIndex4
% %                     RESULTS(dataPointIndex4,1)
% %                     dataPointIndex5
% %                     dataPointIndex4(dataPointIndex5)
% %                     RESULTS(dataPointIndex4(dataPointIndex5),3)
                dataPointIndex6 = find((RESULTS(:,1) <= indentationDepth(j)+0.1*ErrorIndentationDepth));
                dataPointIndex7 = find((RESULTS(:,1) >= indentationDepth(j)-0.1*ErrorIndentationDepth));
                dataPointIndex8 = intersect(dataPointIndex6,dataPointIndex7);
                [maxumumvalue dataPointIndex9] = max(RESULTS(dataPointIndex8,3));
                if ~isempty(dataPointIndex9)
                    if abs(maxumumvalue-RESULTS(dataPointIndex4(dataPointIndex5),3))>10
                        CounterOOO(j) = CounterOOO(j) + 1;
                    end;
                    elasticityData(q,j) = maxumumvalue;
                elseif ~isempty(dataPointIndex5)
                    elasticityData(q,j) = RESULTS(dataPointIndex4(dataPointIndex5),3); 
                elseif isempty(dataPointIndex2) && isempty(dataPointIndex2)
                    elasticityData(q,j)=0;
                    CounterOO(j) = CounterOO(j) + 1;
                else
% %                     dataPointIndex2
% %                     dataPointIndex3
% %                     dataPointIndex4
% %                     dataPointIndex5
% %                     RESULTS(:,1)
% % % %                     indentationDepth(j)
% % % %                     RESULTS(1,1)
                    elasticityData(q,j)=NaN;
                end;
%             if ~isempty(dataPointIndex5)
%                 %while dataPointIndex < RESULT_SIZE(1) && abs(RESULTS(dataPointIndex+1,1) - indentationDepth(j)) < abs(RESULTS(dataPointIndex,1) - indentationDepth(j))
%                     %dataPointIndex = dataPointIndex + 1;
%                 %end
%                 if (abs(RESULTS(dataPointIndex4(dataPointIndex5),1) - indentationDepth(j)) < ErrorIndentationDepth)
%                     elasticityData(q,j) = RESULTS(dataPointIndex5,3); 
%                     'Hallo'
%                     
%                 else
%                     elasticityData(q,j)= 30000;
%                     'Hallo2'
%                 end
%             else
%                 CounterOO(j) = CounterOO(j) + 1;
%             end
            end;
        end
    end
% %     if strcmp(found_match,'not found')==1
% %         %fileString
% %     end
end
end;

%% create full table including non-existent x-y pairs.
minStageX = min(stageX);
maxStageX = max(stageX);
minStageY = min(stageY);
maxStageY = max(stageY);
NumberOfStepsInX = round((maxStageX - minStageX)/measurementResolution);
NumberOfStepsInY = round((maxStageY - minStageY)/measurementResolution);
fullX = [];
fullY = [];
for q = 0 : NumberOfStepsInY
    for w = 0 : NumberOfStepsInX
        fullXvalue = minStageX + (w * measurementResolution);
        fullX = [fullX; fullXvalue];
        fullYvalue = minStageY + (q * measurementResolution);
        fullY = [fullY; fullYvalue];
    end
end

%% make full elasticity Vector where nonexistent values should be NaN
fullElasticityData = zeros (length(fullX),length(indentationDepth));
fullElasticityData(:,:) = NaN;

%% find values that I have for the full Height Vector

SizeEData = size(elasticityData)
length(fullElasticityData)
SizeFullEData = size(fullElasticityData)
for j = 1:length(indentationDepth)
for q = 1:length(fullX)
    for w = 1:SizeEData(1)
        if ((stageX(w) > fullX(q) - 0.05 * measurementResolution) && ...
                (stageX(w) < fullX(q) + 0.05 * measurementResolution) && ...
                (stageY(w) > fullY(q) - 0.05 * measurementResolution) && ...
                (stageY(w) < fullY(q) + 0.05 * measurementResolution))
            fullElasticityData(q,j) = elasticityData(w,j);
        end
    end
end
end

%% ...
% % fullElasticityData;
for j = 1:length(indentationDepth)
    minElasticity(j)=min(fullElasticityData(:,j))
    maxElasticity(j)=max(fullElasticityData(:,j))
end;
    
if strcmp(EndpointforPlot,'y')==1
   ENDE = maxElasticity;
elseif strcmp(EndpointforPlot,'yy')==1
   ENDE = max(maxElasticity);
end
%elasticityRange = maxElasticity - minElasticity;
%elasticityColorValues = zeros(length(fullElasticityData),1);
%for q = 1 : length(fullElasticityData)
%    if isnan(fullElasticityData(q))
%        elasticityColorValues(q) = 1;
%    else 
%        elasticityColorValues(q) = 2+62*(fullElasticityData(q)/elasticityRange);
%    end
%end

%% make matrix for the colormap
INDEX = 1;
elasticityMapMatrix = zeros(int8(NumberOfStepsInX)+1,int8(NumberOfStepsInY)+1);
for j = 1:length(indentationDepth)
    for q = 1 : length(fullX)
        elasticityMapMatrix(q) = fullElasticityData(q,j);
        if fullElasticityData(q,j)==0
   
            %DropoutMatrix(1,INDEX) = floor(q/NumberOfStepsInY)
            if  mod(q,NumberOfStepsInY)==0
                %DropoutMatrix(2,INDEX) = NumberOfStepsInY;
            else
               % DropoutMatrix(2,INDEX) = q - floor(q/NumberOfStepsInY);
            end;
            %INDEX = INDEX + 1;
        end;
    end
    
    %DropoutMatrix
    %% draw the colormap
    Final_Elasticities(:,:,j)=fliplr(elasticityMapMatrix');
    size(Final_Elasticities);
    [y_nan, x_nan] = find(isnan(Final_Elasticities(:,:,j)));
    [y_big, x_big] = find(Final_Elasticities(:,:,j)==NaN);
    
    if length(ENDE)==1
        h=figure('visible','off');
        imagesc([minStageX,maxStageX],[minStageY,maxStageY],Final_Elasticities(:,:,j),[0,ENDE]); colormap hot
        %text(minStageX+[x_nan-1]*measurementResolution, minStageY+[y_nan-1]*measurementResolution,'x', 'FontSize',7, 'Color', [1 0 0])
        %text(minStageX+[x_big-1]*measurementResolution, minStageY+[y_big-1]*measurementResolution,'o', 'FontSize',7, 'Color', [0 0 0])
        colorbar;
        axis image ij
        axis off
        %print(h, '-dbmp16m', strcat(PathName,num2str(indentationDepth(j)*10^7),'-fixed'));
        saveas(h,strcat(PathName,num2str(indentationDepth(j)*10^7),'-fixed'), 'tif') ;
        saveas(h,strcat(PathName,num2str(indentationDepth(j)*10^7),'-fixed'), 'fig') ;
        close(h)
    else
        h=figure('visible','off');
        ENDE(j)
        imagesc([minStageX,maxStageX],[minStageY,maxStageY],Final_Elasticities(:,:,j),[0,ENDE(j)]); colormap hot
        %text(minStageX+[x_nan-1]*measurementResolution, minStageY+[y_nan-1]*measurementResolution,'x', 'FontSize',7, 'Color', [1 0 0])
        %text(minStageX+[x_big-1]*measurementResolution, minStageY+[y_big-1]*measurementResolution,'o', 'FontSize',7, 'Color', [0 0 0])
        colorbar;
        axis image ij
        axis off
        %print(h, '-dbmp16m', strcat(PathName,num2str(indentationDepth(j)*10^7)));
        saveas(h,strcat(PathName,num2str(indentationDepth(j)*10^7)), 'tif') ;
        saveas(h,strcat(PathName,num2str(indentationDepth(j)*10^7)), 'fig') ;
        close(h)
    end 
    
    strcat('Indentation', num2str(indentationDepth(j)*10^7), '.txt')
    dlmwrite(strcat(PathName,strcat('Indentation', num2str(indentationDepth(j)*10^7), '.txt')), Final_Elasticities(:,:,j),'delimiter', '\t', 'newline', 'pc');
end

% % HalloHallo=Final_Elasticities(:,:,3);
% % WhiteNaN = HalloHallo(~isnan(HalloHallo));
% % WhiteNaN3 = WhiteNaN(WhiteNaN~=30000);
% % WhiteNaN3 = WhiteNaN3(WhiteNaN3>0);
% % mean(mean(WhiteNaN3))



%careful in the matrix the 4th row can correspond to 3 * 100 microns into
%the measurement.

%% draw the colormap
%imagesc([maxStageX,minStageX],[maxStageY,minStageY],elasticityMapMatrix',[0,ENDE]);
%colorbar;
%%image([maxStageX,minStageX],[maxStageY,minStageY],elasticityMapMatrix');
%axis image ij
%axis off
CounterOO
CounterOOO