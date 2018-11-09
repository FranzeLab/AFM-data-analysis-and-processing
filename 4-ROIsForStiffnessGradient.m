%To do analysis for specific indentation depth, change line 36 as needed
%This version is set up for analysis at maximum force.

%This version is set up for analysis of a 50 micron x50 micron ROI. 
%Adjust as needed.

%Ensure that you have the correct spatial resolution of the stiffness measurements.  

%NOTE!! Files required: IndentationXXXX.txt (matrix of values from
%stiffness map); GanzPunkte (image of sample, showing the corners of map);
%and overlay image (map on top of GanzPunkte)

%Image format: TIFF files, resolution 1024x768 (crop if necessary)

clc;                % Clear command window.
clear;              % Delete all variables.
close all;          % Close all figure windows except those created by imtool.
imtool close all;	% Close all figure windows created by imtool.
workspace;          % Make sure the workspace panel is showing.
fontSize = 16;

Llength=25;
Lwidth=50;
Resolutionn=25;



[baseFileName,folder] = uigetfile({'*.tif;*.png','Overlay Image'},'Select curve','MultiSelect','on');
% Get the full filename, with path prepended.
fullFileName = fullfile(folder, baseFileName);
% Check if file exists.
if ~exist(fullFileName, 'file')
	% File doesn't exist -- didn't find it there.  Check the search path for it.
	fullFileName = baseFileName; % No path this time.
	if ~exist(fullFileName, 'file')
		% Still didn't find it.  Alert user.
		errorMessage = sprintf('Error: %s does not exist in the search path folders.', fullFileName);
		uiwait(warndlg(errorMessage));
		return;
	end
end
GreyImage = imread(fullFileName);
%[baseFileName2,folder2] = uigetfile({'*.txt','Indentation Matrix From ElasticityMapp'},'Select curve','MultiSelect','on');
filename = [strcat(folder, 'IndentationIvan.txt')];
EMapp = importdata(filename);
SizeEMapp = size(EMapp);

figure;
imshow(GreyImage, []);
set(gcf, 'Position', get(0,'Screensize')); 
message = sprintf('Click on the LL and then the UR and then press ENTER.');
uiwait(msgbox(message));
[TIPx TIPy]=ginput;
TIPx=round(TIPx);
TIPy=round(TIPy);
close all

    GreyImagePoints = imread(fullfile(folder, 'GanzPunkte.tif'));
    [Positions(:,1), Positions(:,2)]=find(GreyImagePoints(:,:,1)==255 & GreyImagePoints(:,:,2)==0 & GreyImagePoints(:,:,3)==0);
    SizePosition=size(Positions);
    Helper=0;
        for jj=1:SizePosition(1)
            MM=0;
            for kk=-2:1:2
                for ll=-2:1:2
                    if ~isempty(find(Positions==Positions(jj,1)+kk)) && ~isempty(find(Positions==Positions(jj,2)+ll))
                       MM=MM+1;
                       if MM==25
                           if Helper==0
                               Helper=1;
                               TopPos(1,1:2)=Positions(jj,1:2);
                           else
                               TopPos(2,1:2)=Positions(jj,1:2);
                           end;
                       end
                    end
                end
            end
        end
% % %         TopPos
    if TopPos(1,1)<TopPos(2,1)
        TopPos(3,1:2)=TopPos(1,1:2);
        TopPos(1,1:2)=TopPos(2,1:2);
        TopPos(2,1:2)=TopPos(1,1:2);
    end;
    LLy=TopPos(1,1);
    LLx=TopPos(1,2);
    URy=TopPos(2,1);
    URx=TopPos(2,2);

        figure;
        subplot(1, 1, 1);
        GreyImage = imread(fullFileName);
        GreyImage(URy-2:URy+2,URx-2:URx+2,1)=255;
        GreyImage(URy-2:URy+2,URx-2:URx+2,2)=0;
        GreyImage(URy-2:URy+2,URx-2:URx+2,3)=0;

        GreyImage(LLy-2:LLy+2,LLx-2:LLx+2,1)=255;
        GreyImage(LLy-2:LLy+2,LLx-2:LLx+2,2)=0;
        GreyImage(LLy-2:LLy+2,LLx-2:LLx+2,3)=0;
        imshow(GreyImage, []);
        set(gcf, 'Position', get(0,'Screensize')); 
        message = sprintf(strcat('Left click and hold to mark the tracts curvature.\nSimply lift the mouse button to finish'));
        uiwait(msgbox(message));
        hFH = imfreehand();
        % Create a binary image ("mask") from the ROI object.
%         binaryImage = hFH.createMask();
        xy = hFH.getPosition;
        Curveee(1:768,1:1024,1:3)=0;
        for i=1:length(xy)
            Curveee(round(xy(i,2)),round(xy(i,1)),1)=255;
        end;
        close all
%         plot(xy)

% % subplot(1, 2, 1);
% % set(gcf, 'Position', get(0,'Screensize')); 
% % imshow(GreyImage, []);
% % % title('Original Greyscale Image', 'FontSize', fontSize);
% % 
% % subplot(1, 2, 2);
% % imshow(Curveee);
% % % title('Binary masks of the regions', 'FontSize', fontSize);

h=0.01;
ResizeFactor = mean([(Resolutionn*SizeEMapp(1))/abs(TIPy(1)-TIPy(2)) (Resolutionn*SizeEMapp(2))/abs(TIPx(2)-TIPx(1))]);
xxyy(:,1)=(xy(1:5:end,1)-xy(1,1))*ResizeFactor;
xxyy(:,2)=(xy(1:5:end,2)-xy(1,2))*ResizeFactor;
x=smooth(xxyy(:,1),10);
y=smooth(xxyy(:,2),10);

% Curveee(1:768,1:1024,1:3)=0;
        for i=1:length(x)
            GreyImage(round(y(i)/ResizeFactor+xy(1,2))-2:round(y(i)/ResizeFactor+xy(1,2))+2,round(x(i)/ResizeFactor+xy(1,1))-2:round(x(i)/ResizeFactor+xy(1,1))+2,1)=255;
            GreyImage(round(y(i)/ResizeFactor+xy(1,2))-2:round(y(i)/ResizeFactor+xy(1,2))+2,round(x(i)/ResizeFactor+xy(1,1))-2:round(x(i)/ResizeFactor+xy(1,1))+2,2)=0;
            GreyImage(round(y(i)/ResizeFactor+xy(1,2))-2:round(y(i)/ResizeFactor+xy(1,2))+2,round(x(i)/ResizeFactor+xy(1,1))-2:round(x(i)/ResizeFactor+xy(1,1))+2,3)=0;
        end;

for i=1:floor((length(x)-6)/5)
    xnew(i) = mean(x(4+(i-1)*5:8+(i-1)*5));
    ynew(i) = mean(y(4+(i-1)*5:8+(i-1)*5));
    p(i,1:2) = polyfit(x(4+(i-1)*5:8+(i-1)*5),y(4+(i-1)*5:8+(i-1)*5),1);
end
if mod(length(x)-6,5)==0
else
    xnew(i+1) = mean(x(length(x)-3-mod(length(x)-2,5):length(x)-3));
    ynew(i+1) = mean(y(length(x)-3-mod(length(x)-2,5):length(x)-3));
    p(i+1,1:2) = polyfit(x(length(x)-3-mod(length(x)-2,5):length(x)-3),y(length(x)-3-mod(length(x)-2,5):length(x)-3),1);
end

PointMap(1:768,1:1024,1:length(xnew))=0;
for i=1:length(xnew)
% %     PointMap(round(ynew(i)/ResizeFactor+xy(1,2)),round(xnew(i)/ResizeFactor+xy(1,1)),i)=1;
	GreyImage(round(ynew(i)/ResizeFactor+xy(1,2))-2:round(ynew(i)/ResizeFactor+xy(1,2))+2,round(xnew(i)/ResizeFactor+xy(1,1))-2:round(xnew(i)/ResizeFactor+xy(1,1))+2,1)=0;
	GreyImage(round(ynew(i)/ResizeFactor+xy(1,2))-2:round(ynew(i)/ResizeFactor+xy(1,2))+2,round(xnew(i)/ResizeFactor+xy(1,1))-2:round(xnew(i)/ResizeFactor+xy(1,1))+2,2)=0;
    GreyImage(round(ynew(i)/ResizeFactor+xy(1,2))-2:round(ynew(i)/ResizeFactor+xy(1,2))+2,round(xnew(i)/ResizeFactor+xy(1,1))-2:round(xnew(i)/ResizeFactor+xy(1,1))+2,3)=255;
end;
        
% % subplot(1, 2, 2);
% % 
% % imshow(GreyImage);
% % title('Binary masks of the regions', 'FontSize', fontSize);

h=figure;
plot(x,y,'x')
set(gcf, 'Position', get(0,'Screensize')); 
saveas(gcf,strcat(folder,'1'),'fig');
hgexport(gcf, strcat(folder,'1.jpg'), hgexport('factorystyle'), 'Format', 'jpeg');
% imwrite(GreyImage,strcat(folder,'GanzPunkte.tif'), 'tiff') ;

X=diff(x);
X2=diff(X);
Y=diff(y)/h;
Y2=diff(Y)/h;
length(x)
length(Y)
length(Y2)

K=Y2./((1+Y(1:end-1).^2).^(3/2));

for i=1:(length(x)-2)
% %     c=sqrt((x(i+1)-x(i)).^2+(y(i+1)-y(i)).^2);
% %     a=sqrt((x(i+2)-x(i)).^2+(y(i+2)-y(i)).^2);
% %     b=sqrt((x(i+2)-x(i+1)).^2+(y(i+2)-y(i+1)).^2);
    K2(i) = 2*((x(i+1)-x(i)).*(y(i+2)-y(i))-(x(i+2)-x(i)).*(y(i+1)-y(i))) ./ ...
    sqrt(((x(i+1)-x(i)).^2+(y(i+1)-y(i)).^2)*((x(i+2)-x(i)).^2+(y(i+2)-y(i)).^2)*((x(i+2)-x(i+1)).^2+(y(i+2)-y(i+1)).^2));
% %     Kcheck(i) =sqrt((a+b+c)*(b+c-a)*(c+a-b)*(a+b-c))/sqrt(((x(i+1)-x(i)).^2+(y(i+1)-y(i)).^2)*((x(i+2)-x(i)).^2+(y(i+2)-y(i)).^2)*((x(i+2)-x(i+1)).^2+(y(i+2)-y(i+1)).^2))
end;

% for i=1:length(K)
%     if K(i)<0
%         K3(i)=-K2(i);
%     else
%         K3(i)=K2(i);
%     end;
% end;

% % figure;
% % plot(phi,y,'b')
% % hold on
% % plot(phi,y,'r')
% % hold on
% % plot(phi,y,'g')

hold on
figure;
% plot(x(2:end-1),K,'b')
hold on
plot(y(2:end-1),K2,'xr')
K3=smooth(K2,15);
hold all
plot(y(2:end-1),K3,'xk')

for i=1:floor((length(x)-6)/5)
    K3new(i) = mean(K3(3+(i-1)*5:7+(i-1)*5));
end
if mod(length(x)-6,5)==0
else
    K3new(i+1) = mean(K3(length(x)-4-mod(length(x)-6,5):length(x)-4));
end
plot(ynew,K3new,'xb')
set(gcf, 'Position', get(0,'Screensize')); 
saveas(gcf,strcat(folder,'2'),'fig');
hgexport(gcf, strcat(folder,'2.jpg'), hgexport('factorystyle'), 'Format', 'jpeg');


% % figure;
% % set(gcf, 'Position', get(0,'Screensize')); 
% % imshow(GreyImage, []);
% % title('Original Greyscale Image', 'FontSize', fontSize);

ResizeFactor2 = mean([abs(TIPy(1)-TIPy(2))/SizeEMapp(1) abs(TIPx(2)-TIPx(1))/SizeEMapp(2)]);
% % figure;
% % imshow(EMapp, []);
% % figure;
% % imshow(imresize(EMapp,ResizeFactor2,'box'), []);
Emapp2Size=size(imresize(EMapp,ResizeFactor2,'box'))

PointMap3(1:768,1:1024)=0;
PointMap3(TIPy(2):TIPy(2)+Emapp2Size(1)-1,TIPx(1):TIPx(1)+Emapp2Size(2)-1)=imresize(EMapp,ResizeFactor2,'box');

figure;
subplot(1, 2, 1);
set(gcf, 'Position', get(0,'Screensize')); 
imshow(GreyImage, []);
% title('Original Greyscale Image', 'FontSize', fontSize);

subplot(1, 2, 2);
imshow(PointMap3, []);
saveas(gcf,strcat(folder,'3'),'fig');
hgexport(gcf, strcat(folder,'3.jpg'), hgexport('factorystyle'), 'Format', 'jpeg');

PointMap(1:768,1:1024,1:length(xnew))=0;
PointMap4(1:768,1:1024,1:length(xnew))=0;

for i=1:length(xnew)-1
% %     n(i) = ynew(i)+1/p(i,1)*xnew(i);
% %     L=0;
% %     xvar(i,1)=xnew(i);
% %     while L<100
% %         xvar(i,1)=xvar(i,1)+0.001;
% %         L=sqrt((ynew(i)-n(i)+1/p(i,1)*xvar(i,1))^2+(xnew(i)-xvar(i,1))^2);
% %     end
% %     yvar(i,1)=-1/p(i,1)*xvar(i,1)+n(i);
% %     xvar(i,2)=2*xnew(i)-xvar(i,1);
% %     yvar(i,2)=2*ynew(i)-yvar(i,1);
% % % %     [yvar xvar ynew(i) xnew(i)]
% % % %     sqrt((yvar-ynew(i))^2+(xvar-xnew(i))^2)
% %     L=0;
% %     xvar(i,3)=xnew(i);
% %     while L<50
% %         xvar(i,3)=xvar(i,3)+0.001;
% %         L=sqrt((ynew(i)-p(i,2)-p(i,1)*xvar(i,3))^2+(xnew(i)-xvar(i,3))^2);
% %     end
% %     yvar(i,3)=p(i,1)*xvar(i,3)+p(i,2);
% %     xvar(i,4)=2*xnew(i)-xvar(i,3);
% %     yvar(i,4)=2*ynew(i)-yvar(i,3);
% %     for j=1:4
% %         GreyImage(round(yvar(i,j)/ResizeFactor+xy(1,2))-2:round(yvar(i,j)/ResizeFactor+xy(1,2))+2, ...
% %             round(xvar(i,j)/ResizeFactor+xy(1,1))-2:round(xvar(i,j)/ResizeFactor+xy(1,1))+2,1)=0;
% %         GreyImage(round(yvar(i,j)/ResizeFactor+xy(1,2))-2:round(yvar(i,j)/ResizeFactor+xy(1,2))+2, ...
% %             round(xvar(i,j)/ResizeFactor+xy(1,1))-2:round(xvar(i,j)/ResizeFactor+xy(1,1))+2,2)=255;
% %         GreyImage(round(yvar(i,j)/ResizeFactor+xy(1,2))-2:round(yvar(i,j)/ResizeFactor+xy(1,2))+2, ...
% %             round(xvar(i,j)/ResizeFactor+xy(1,1))-2:round(xvar(i,j)/ResizeFactor+xy(1,1))+2,3)=0;
% %     end
% %     achsenew(i,1)=yvar(i,1)-p(i,1)*xvar(i,1);
% %     L=0;
% %     xvar2(i,1)=xvar(i,1);
% %     while L<50
% %         xvar2(i,1)=xvar2(i,1)+0.001;
% %         L=sqrt((yvar(i,1)-achsenew(i,1)-p(i,1)*xvar2(i,1))^2+(xvar(i,1)-xvar2(i,1))^2);
% %         PointMap(round((p(i,1)*xvar2(i,1)+achsenew(i,1))/ResizeFactor+xy(1,2)),round(xvar2(i,1)/ResizeFactor+xy(1,1)),i)=1;
% %         PointMap(round((p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1))/ResizeFactor+xy(1,2)),round((2*xvar(i,1)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=1;
% %     end
% %     yvar2(i,1)=p(i,1)*xvar2(i,1)+achsenew(i,1);
% %     xvar2(i,2)=2*xvar(i,1)-xvar2(i,1);
% %     yvar2(i,2)=2*yvar(i,1)-yvar2(i,1);
% % % %     [yvar2 xvar2 ynew(i) xnew(i)]
% % % %     sqrt((yvar2-ynew(i))^2+(xvar2-xnew(i))^2)
% %     L=0;
% %     achsenew(i,2)=yvar(i,2)-p(i,1)*xvar(i,2);
% %     xvar2(i,3)=xvar(i,2);
% %     while L<50
% %         xvar2(i,3)=xvar2(i,3)+0.001;
% %         L=sqrt((yvar(i,2)-achsenew(i,2)-p(i,1)*xvar2(i,3))^2+(xvar(i,2)-xvar2(i,3))^2);
% %         PointMap(round((p(i,1)*xvar2(i,3)+achsenew(i,2))/ResizeFactor+xy(1,2)),round(xvar2(i,3)/ResizeFactor+xy(1,1)),i)=1;
% %         PointMap(round((p(i,1)*(2*xvar(i,2)-xvar2(i,3))+achsenew(i,2))/ResizeFactor+xy(1,2)),round((2*xvar(i,2)-xvar2(i,3))/ResizeFactor+xy(1,1)),i)=1;
% %     end
% %     yvar2(i,3)=p(i,1)*xvar2(i,3)+achsenew(i,2);
% %     xvar2(i,4)=2*xvar(i,2)-xvar2(i,3);
% %     yvar2(i,4)=2*yvar(i,2)-yvar2(i,3);
% %     
% %     L=0;
% %     achsenew(i,3)=yvar(i,3)+1/p(i,1)*xvar(i,3);
% %     xvar3(i,1)=xvar(i,3);
% %     while L<100
% %         xvar3(i,1)=xvar3(i,1)+0.001;
% %         L=sqrt((yvar(i,3)-achsenew(i,3)+1/p(i,1)*xvar3(i,1))^2+(xvar(i,3)-xvar3(i,1))^2);
% %         PointMap(round((-1/p(i,1)*xvar3(i,1)+achsenew(i,3))/ResizeFactor+xy(1,2)),round(xvar3(i,1)/ResizeFactor+xy(1,1)),i)=1;
% %         PointMap(round((-1/p(i,1)*(2*xvar(i,3)-xvar3(i,1))+achsenew(i,3))/ResizeFactor+xy(1,2)),round((2*xvar(i,3)-xvar3(i,1))/ResizeFactor+xy(1,1)),i)=1;
% %     end
% %     
% %     L=0;
% %     achsenew(i,4)=yvar(i,4)+1/p(i,1)*xvar(i,4);
% %     xvar3(i,2)=xvar(i,4);
% %     while L<100
% %         xvar3(i,2)=xvar3(i,2)+0.001;
% %         L=sqrt((yvar(i,4)-achsenew(i,4)+1/p(i,1)*xvar3(i,2))^2+(xvar(i,4)-xvar3(i,2))^2);
% %         PointMap(round((-1/p(i,1)*xvar3(i,2)+achsenew(i,4))/ResizeFactor+xy(1,2)),round(xvar3(i,2)/ResizeFactor+xy(1,1)),i)=1;
% %         PointMap(round((-1/p(i,1)*(2*xvar(i,4)-xvar3(i,2))+achsenew(i,4))/ResizeFactor+xy(1,2)),round((2*xvar(i,4)-xvar3(i,2))/ResizeFactor+xy(1,1)),i)=1;
% %     end
% % 
% %     for j=1:4
% %         PointMap(round(yvar2(i,j)/ResizeFactor+xy(1,2)),round(xvar2(i,j)/ResizeFactor+xy(1,1)),i)=1;
% %         GreyImage(round(yvar2(i,j)/ResizeFactor+xy(1,2))-2:round(yvar2(i,j)/ResizeFactor+xy(1,2))+2, ...
% %             round(xvar2(i,j)/ResizeFactor+xy(1,1))-2:round(xvar2(i,j)/ResizeFactor+xy(1,1))+2,1)=0;
% %         GreyImage(round(yvar2(i,j)/ResizeFactor+xy(1,2))-2:round(yvar2(i,j)/ResizeFactor+xy(1,2))+2, ...
% %             round(xvar2(i,j)/ResizeFactor+xy(1,1))-2:round(xvar2(i,j)/ResizeFactor+xy(1,1))+2,2)=0;
% %         GreyImage(round(yvar2(i,j)/ResizeFactor+xy(1,2))-2:round(yvar2(i,j)/ResizeFactor+xy(1,2))+2, ...
% %             round(xvar2(i,j)/ResizeFactor+xy(1,1))-2:round(xvar2(i,j)/ResizeFactor+xy(1,1))+2,3)=0;
% %     end
    
% % for i=1:floor((length(x)-6)/5)
% %     xnew(i) = mean(x(4+(i-1)*5:8+(i-1)*5));
% %     xnew(i+1) = mean(x(length(x)-3-mod(length(x)-2,5):length(x)-3));

    n(i) = ynew(i)+1/p(i,1)*xnew(i);
%     achsenew(i,1)=yvar(i,1)-p(i,1)*xvar(i,1);
    L1=0;
    L2=0;
    xvar(i,1)=xnew(i);
    while L1<Lwidth
        if abs(1/p(i,1))>1
            xvar(i,1)=xvar(i,1)+0.1;
        else
            xvar(i,1)=xvar(i,1)+abs(1/p(i,1))-1/2*abs(1/p(i,1));
        end
        yvar(i,1)=-1/p(i,1)*xvar(i,1)+n(i);
        if yvar(i,1)<=ynew(i) && x(4+(i-1)*5)-x(8+(i-1)*5)>=0;
            PointMap(round(yvar(i,1)/ResizeFactor+xy(1,2)),round(xvar(i,1)/ResizeFactor+xy(1,1)),i)=1;
            PointMap4(round((2*ynew(i)-yvar(i,1))/ResizeFactor+xy(1,2)),round((2*xnew(i)-xvar(i,1))/ResizeFactor+xy(1,1)),i)=1;
        elseif yvar(i,1)>ynew(i) && x(4+(i-1)*5)-x(8+(i-1)*5)<0;
            PointMap(round(yvar(i,1)/ResizeFactor+xy(1,2)),round(xvar(i,1)/ResizeFactor+xy(1,1)),i)=1;
            PointMap4(round((2*ynew(i)-yvar(i,1))/ResizeFactor+xy(1,2)),round((2*xnew(i)-xvar(i,1))/ResizeFactor+xy(1,1)),i)=1;
        elseif yvar(i,1)<=ynew(i) && x(4+(i-1)*5)-x(8+(i-1)*5)<0;
            PointMap4(round(yvar(i,1)/ResizeFactor+xy(1,2)),round(xvar(i,1)/ResizeFactor+xy(1,1)),i)=1;
            PointMap(round((2*ynew(i)-yvar(i,1))/ResizeFactor+xy(1,2)),round((2*xnew(i)-xvar(i,1))/ResizeFactor+xy(1,1)),i)=1;
        else
            PointMap4(round(yvar(i,1)/ResizeFactor+xy(1,2)),round(xvar(i,1)/ResizeFactor+xy(1,1)),i)=1;
            PointMap(round((2*ynew(i)-yvar(i,1))/ResizeFactor+xy(1,2)),round((2*xnew(i)-xvar(i,1))/ResizeFactor+xy(1,1)),i)=1;
        end;
% % %         if yvar(i,1)<=ynew(i);
% % %             PointMap(round(yvar(i,1)/ResizeFactor+xy(1,2)),round(xvar(i,1)/ResizeFactor+xy(1,1)),i)=1;
% % %         else
% % %             PointMap(round((2*ynew(i)-yvar(i,1))/ResizeFactor+xy(1,2)),round((2*xnew(i)-xvar(i,1))/ResizeFactor+xy(1,1)),i)=0.5;
% % %         end;
        achsenew(i,1)=yvar(i,1)-p(i,1)*xvar(i,1);
        L2=0;
        xvar2(i,1)=xvar(i,1);
        while L2<Llength
            if abs(1/p(i,1))>1
                xvar2(i,1)=xvar2(i,1)+0.1;
            else
                xvar2(i,1)=xvar2(i,1)+abs(1/p(i,1))-1/2*abs(1/p(i,1));
            end
            if yvar(i,1)<=ynew(i) && x(4+(i-1)*5)-x(8+(i-1)*5)>=0;
                PointMap(round((p(i,1)*xvar2(i,1)+achsenew(i,1))/ResizeFactor+xy(1,2)),round(xvar2(i,1)/ResizeFactor+xy(1,1)),i)=1;
                PointMap(round((p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1))/ResizeFactor+xy(1,2)),round((2*xvar(i,1)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=1;
                PointMap4(round((2*ynew(i)-(p(i,1)*xvar2(i,1)+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=1; %
                PointMap4(round((2*ynew(i)-(p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-(2*xvar(i,1)-xvar2(i,1)))/ResizeFactor+xy(1,1)),i)=1;
            elseif yvar(i,1)>ynew(i) && x(4+(i-1)*5)-x(8+(i-1)*5)<0;
                PointMap(round((p(i,1)*xvar2(i,1)+achsenew(i,1))/ResizeFactor+xy(1,2)),round(xvar2(i,1)/ResizeFactor+xy(1,1)),i)=1;
                PointMap(round((p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1))/ResizeFactor+xy(1,2)),round((2*xvar(i,1)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=1;
                PointMap4(round((2*ynew(i)-(p(i,1)*xvar2(i,1)+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=1; %
                PointMap4(round((2*ynew(i)-(p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-(2*xvar(i,1)-xvar2(i,1)))/ResizeFactor+xy(1,1)),i)=1;
            elseif yvar(i,1)<=ynew(i) && x(4+(i-1)*5)-x(8+(i-1)*5)<0;
                PointMap4(round((p(i,1)*xvar2(i,1)+achsenew(i,1))/ResizeFactor+xy(1,2)),round(xvar2(i,1)/ResizeFactor+xy(1,1)),i)=1;
                PointMap4(round((p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1))/ResizeFactor+xy(1,2)),round((2*xvar(i,1)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=1;
                PointMap(round((2*ynew(i)-(p(i,1)*xvar2(i,1)+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=1; %
                PointMap(round((2*ynew(i)-(p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-(2*xvar(i,1)-xvar2(i,1)))/ResizeFactor+xy(1,1)),i)=1;
            else
                PointMap4(round((p(i,1)*xvar2(i,1)+achsenew(i,1))/ResizeFactor+xy(1,2)),round(xvar2(i,1)/ResizeFactor+xy(1,1)),i)=1;
                PointMap4(round((p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1))/ResizeFactor+xy(1,2)),round((2*xvar(i,1)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=1;
                PointMap(round((2*ynew(i)-(p(i,1)*xvar2(i,1)+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=1; %
                PointMap(round((2*ynew(i)-(p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-(2*xvar(i,1)-xvar2(i,1)))/ResizeFactor+xy(1,1)),i)=1;
            end
% %             if yvar(i,1)<=ynew(i);
% %                 PointMap(round((p(i,1)*xvar2(i,1)+achsenew(i,1))/ResizeFactor+xy(1,2)),round(xvar2(i,1)/ResizeFactor+xy(1,1)),i)=1;
% %                 PointMap(round((p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1))/ResizeFactor+xy(1,2)),round((2*xvar(i,1)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=1;
% %                 PointMap(round((2*ynew(i)-(p(i,1)*xvar2(i,1)+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=0.5; %
% %                 PointMap(round((2*ynew(i)-(p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-(2*xvar(i,1)-xvar2(i,1)))/ResizeFactor+xy(1,1)),i)=0.5;
% %             else
% %                 PointMap(round((p(i,1)*xvar2(i,1)+achsenew(i,1))/ResizeFactor+xy(1,2)),round(xvar2(i,1)/ResizeFactor+xy(1,1)),i)=0.5;
% %                 PointMap(round((p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1))/ResizeFactor+xy(1,2)),round((2*xvar(i,1)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=0.5;
% %                 PointMap(round((2*ynew(i)-(p(i,1)*xvar2(i,1)+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-xvar2(i,1))/ResizeFactor+xy(1,1)),i)=1; %
% %                 PointMap(round((2*ynew(i)-(p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xnew(i)-(2*xvar(i,1)-xvar2(i,1)))/ResizeFactor+xy(1,1)),i)=1;
% %             end
%             PointMap(round((2*var(i,1)-(p(i,1)*(2*xvar(i,1)-xvar2(i,1))+achsenew(i,1)))/ResizeFactor+xy(1,2)),round((2*xvar(i,1)-(2*xnew(i)-xvar2(i,1)))/ResizeFactor+xy(1,1)),i)=1; %
            L2=sqrt((yvar(i,1)-achsenew(i,1)-p(i,1)*xvar2(i,1))^2+(xvar(i,1)-xvar2(i,1))^2)
        end
        L1=sqrt((ynew(i)-n(i)+1/p(i,1)*xvar(i,1))^2+(xnew(i)-xvar(i,1))^2)
    end
% %     yvar(i,1)=-1/p(i,1)*xvar(i,1)+n(i);
% %     xvar(i,2)=2*xnew(i)-xvar(i,1);
% %     yvar(i,2)=2*ynew(i)-yvar(i,1);
    
% %     maxxxx(i)=max(abs((xvar2(i,1)-xnew(i))/ResizeFactor),abs((xvar2(i,2)-xnew(i))/ResizeFactor));
% %     maxyyy(i)=max(abs((yvar2(i,1)-ynew(i))/ResizeFactor),abs((yvar2(i,2)-ynew(i))/ResizeFactor));
    
% % % % % %     handleh=fill([round(xvar2(i,1)/ResizeFactor+xy(1,2)) round(xvar2(i,2)/ResizeFactor+xy(1,2)) round(xvar2(i,4)/ResizeFactor+xy(1,2)) round(xvar2(i,3)/ResizeFactor+xy(1,2))], ...
% % % % % %         [round(yvar2(i,1)/ResizeFactor+xy(1,2)) round(yvar2(i,2)/ResizeFactor+xy(1,2)) round(yvar2(i,4)/ResizeFactor+xy(1,2)) round(yvar2(i,3)/ResizeFactor+xy(1,2))],'r')
% % % % % % %     axis square
% % % % % % %     F=getframe(handleh)
% % % % % %     xnewx=get(get(gca,'Children'),'XData')
% % % % % %     ynewy=get(get(gca,'Children'),'YData')
% %     PointMap(round(ynew(i)/ResizeFactor+xy(1,2)+maxyyy(i)),round(xnew(i)/ResizeFactor+xy(1,1)+maxxxx(i)),i)=1;
% %     PointMap(round(ynew(i)/ResizeFactor+xy(1,2)-maxyyy(i)),round(xnew(i)/ResizeFactor+xy(1,1)+maxxxx(i)),i)=1;
% %     PointMap(round(ynew(i)/ResizeFactor+xy(1,2)+maxyyy(i)),round(xnew(i)/ResizeFactor+xy(1,1)-maxxxx(i)),i)=1;
% %     PointMap(round(ynew(i)/ResizeFactor+xy(1,2)-maxyyy(i)),round(xnew(i)/ResizeFactor+xy(1,1)-maxxxx(i)),i)=1;
    
% for hh=-1:2:1
% %     helper =round(ynew(i)/ResizeFactor+xy(1,2));
% %     if max(((yvar2(i,1)-ynew(i))/ResizeFactor),((yvar2(i,2)-ynew(i))/ResizeFactor))<=0
% %         helper2=1;
% %     else
% %         helper2=-1;
% %     end;
% %     for k=0:round(maxxxx(i))
% %         xpos = round(xnew(i)/ResizeFactor+xy(1,1)) + k;%*hh; %xnew(i)/ResizeFactor+xy(1,1)
% %         ypos = helper;
% %         if PointMap(ypos,xpos,i)==1 && helper2==-1
% %         	break
% %         end
% %         ENDE=0;
% %         while ENDE==0 && ypos<round(ynew(i)/ResizeFactor+xy(1,2))+round(maxyyy(i))-1 && ypos>round(ynew(i)/ResizeFactor+xy(1,2))-round(maxyyy(i))+1 ...
% %                 && xpos<round(xnew(i)/ResizeFactor+xy(1,1))+round(maxxxx(i))-1 && xpos>round(xnew(i)/ResizeFactor+xy(1,1))-round(maxxxx(i))+1 
% %             if ypos==helper && PointMap(ypos,xpos,i)==1 && helper2==1
% %                 while PointMap(helper,xpos,i)==1
% % %                     ypos=ypos-1
% %                     helper=helper-1;
% %                     'Hallo'
% %                 end
% %                 ypos=helper;
% % %                     helper=helper-1
% % %                 PointMap(ypos,xpos,i)=1;
% %             elseif ypos~=helper && PointMap(ypos,xpos,i)==1
% %                 ENDE=1;
% %             end
% %                 PointMap(ypos,xpos,i)=1;
% %                 ypos = ypos - 1;
% %         end
% %     end
% end
end

% % for i=1:1%length(xnew)
% % 	GreyImage(round((p(i,1)*(xnew(i)-100)+p(i,2))/ResizeFactor+xy(1,2))-2:round((p(i,1)*(xnew(i)+100)+p(i,2))/ResizeFactor+xy(1,2))+2, ...
% %         round((xnew(i)-100)/ResizeFactor+xy(1,1))-2:round((xnew(i)+100)/ResizeFactor+xy(1,1))+2,1)=0;
% % 	GreyImage(round((p(i,1)*(xnew(i)-100)+p(i,2))/ResizeFactor+xy(1,2))-2:round((p(i,1)*(xnew(i)+100)+p(i,2))/ResizeFactor+xy(1,2))+2, ...
% %         round((xnew(i)-100)/ResizeFactor+xy(1,1))-2:round((xnew(i)+100)/ResizeFactor+xy(1,1))+2,2)=255;
% %     GreyImage(round((p(i,1)*(xnew(i)-100)+p(i,2))/ResizeFactor+xy(1,2))-2:round((p(i,1)*(xnew(i)+100)+p(i,2))/ResizeFactor+xy(1,2))+2, ...
% %         round((xnew(i)-100)/ResizeFactor+xy(1,1))-2:round((xnew(i)+100)/ResizeFactor+xy(1,1))+2,3)=0;
% % end;
% % 
figure;
subplot(1, 2, 1);
set(gcf, 'Position', get(0,'Screensize')); 
imshow(GreyImage, []);
% title('Original Greyscale Image', 'FontSize', fontSize);
PointMap20(1:768,1:1024)=0;
for i=1:length(xnew)
    PointMap20(:,:)=PointMap20(:,:)+PointMap(:,:,i);
end
PointMap20(:,:) = PointMap20(:,:)>0;
subplot(1, 2, 2);
imshow(PointMap20(:,:));
saveas(gcf,strcat(folder,'4'),'fig');
hgexport(gcf, strcat(folder,'4.jpg'), hgexport('factorystyle'), 'Format', 'jpeg');

figure;
subplot(1, 2, 1);
set(gcf, 'Position', get(0,'Screensize')); 
imshow(GreyImage, []);
% title('Original Greyscale Image', 'FontSize', fontSize);
PointMap22(1:768,1:1024)=0;
for i=1:length(xnew)
    PointMap22(:,:)=PointMap22(:,:)+PointMap4(:,:,i);
end
PointMap22(:,:) = PointMap22(:,:)>0;
subplot(1, 2, 2);
imshow(PointMap22(:,:));
saveas(gcf,strcat(folder,'5'),'fig');
hgexport(gcf, strcat(folder,'5.jpg'), hgexport('factorystyle'), 'Format', 'jpeg');

for i=1:length(xnew)-1
    ConvolutionMap{1} = PointMap3.*PointMap4(:,:,i);
    ConvolutionMap{2} = PointMap3.*PointMap(:,:,i);
    ConvHelp1=[];
    ConvHelp2=[];
    ConvHelp3=[];
    ConvHelp4=[];
    ConvHelp1 = find(ConvolutionMap{1}>0);
    ConvHelp2 = find(ConvolutionMap{2}>0);
% %     if length(ConvHelp1)==0 || length(ConvHelp1)==0
% %         ConvHelp3=[];
% %         ConvHelp4=[];
% %     else
    for j=1:length(ConvHelp1)
        ConvHelp3(j)=ConvolutionMap{1}(ConvHelp1(j));
    end
    for j=1:length(ConvHelp2)
        ConvHelp4(j)=ConvolutionMap{2}(ConvHelp2(j));
    end
% %     end;
    Matter1(i)=mean(ConvHelp3);
    Matter2(i)=mean(ConvHelp4);
    Gradient1(i)=(mean(ConvHelp3)-mean(ConvHelp4))/(Lwidth);
    Gradient2(i)=(mean(ConvHelp3)/mean(ConvHelp4));
end

ConvolutionMap{1} = PointMap3.*PointMap22(:,:);
ConvolutionMap{2} = PointMap3.*PointMap20(:,:);
ConvHelp1=[];
ConvHelp2=[];
ConvHelp3=[];
ConvHelp4=[];
ConvHelp1 = find(ConvolutionMap{1}>0);
ConvHelp2 = find(ConvolutionMap{2}>0);
for j=1:length(ConvHelp1)
	ConvHelp3(j)=ConvolutionMap{1}(ConvHelp1(j));
end
for j=1:length(ConvHelp2)
	ConvHelp4(j)=ConvolutionMap{2}(ConvHelp2(j));
end
Matter1(length(xnew))=mean(ConvHelp3);
Matter2(length(xnew))=mean(ConvHelp4);
Gradient1(length(xnew))=(mean(ConvHelp3)-mean(ConvHelp4))/(Lwidth)
Gradient2(length(xnew))=(mean(ConvHelp3)/mean(ConvHelp4))
[K3new mean(K3new)]

figure;
subplot(2, 2, 1);
set(gcf, 'Position', get(0,'Screensize')); 
imshow(PointMap3, []);

subplot(2, 2, 2);
imshow(PointMap3.*PointMap20(:,:)/max(max(PointMap3)));
subplot(2, 2, 3);
imshow(PointMap3.*PointMap22(:,:)/max(max(PointMap3)));

saveas(gcf,strcat(folder,'6'),'fig');
hgexport(gcf, strcat(folder,'6.jpg'), hgexport('factorystyle'), 'Format', 'jpeg');

figure;
set(gcf, 'Position', get(0,'Screensize')); 
subplot(2, 2, 1);
plot(Gradient1(1:end-1),K3new(1:end-1),'x')
subplot(2, 2, 2);
plot(Gradient2(1:end-1),K3new(1:end-1),'x')
subplot(2, 2, 3);
plot(Gradient1(1:end-1),K3new(2:end),'x')

saveas(gcf,strcat(folder,'7'),'fig');
hgexport(gcf, strcat(folder,'7.jpg'), hgexport('factorystyle'), 'Format', 'jpeg');

if exist(strcat(folder,'Gradient1',fullFileName(end-7:end-4),'.txt'),'file')==0
    fid=fopen((strcat(folder,'Gradient1',fullFileName(end-7:end-4),'.txt')),'w');
    fclose(fid);
    dlmwrite(strcat(strcat(folder,'Gradient1',fullFileName(end-7:end-4),'.txt')), Gradient1,'delimiter', '\t', 'newline', 'pc');
else
    dlmwrite(strcat(strcat(folder,'Gradient1',fullFileName(end-7:end-4),'.txt')), Gradient1,'delimiter', '\t', 'newline', 'pc');
end;

if exist(strcat(folder,'Gradient2',fullFileName(end-7:end-4),'.txt'),'file')==0
    fid=fopen((strcat(folder,'Gradient2',fullFileName(end-7:end-4),'.txt')),'w');
    fclose(fid);
    dlmwrite(strcat(strcat(folder,'Gradient2',fullFileName(end-7:end-4),'.txt')), Gradient2,'delimiter', '\t', 'newline', 'pc');
else
    dlmwrite(strcat(strcat(folder,'Gradient2',fullFileName(end-7:end-4),'.txt')), Gradient2,'delimiter', '\t', 'newline', 'pc');
end;
if exist(strcat(folder,'Curvature',fullFileName(end-7:end-4),'.txt'),'file')==0
    fid=fopen((strcat(folder,'Curvature',fullFileName(end-7:end-4),'.txt')),'w');
    fclose(fid);
    dlmwrite(strcat(strcat(folder,'Curvature',fullFileName(end-7:end-4),'.txt')), [K3new mean(K3new)],'delimiter', '\t', 'newline', 'pc');
else
    dlmwrite(strcat(strcat(folder,'Curvature',fullFileName(end-7:end-4),'.txt')), [K3new mean(K3new)],'delimiter', '\t', 'newline', 'pc');
end;

if exist(strcat(folder,'Matter1',fullFileName(end-7:end-4),'.txt'),'file')==0
    fid=fopen((strcat(folder,'Matter1',fullFileName(end-7:end-4),'.txt')),'w');
    fclose(fid);
    dlmwrite(strcat(strcat(folder,'Matter1',fullFileName(end-7:end-4),'.txt')), Matter1,'delimiter', '\t', 'newline', 'pc');
else
    dlmwrite(strcat(strcat(folder,'Matter1',fullFileName(end-7:end-4),'.txt')), Matter1,'delimiter', '\t', 'newline', 'pc');
end;

if exist(strcat(folder,'Matter2',fullFileName(end-7:end-4),'.txt'),'file')==0
    fid=fopen((strcat(folder,'Matter2',fullFileName(end-7:end-4),'.txt')),'w');
    fclose(fid);
    dlmwrite(strcat(strcat(folder,'Matter2',fullFileName(end-7:end-4),'.txt')), Matter2,'delimiter', '\t', 'newline', 'pc');
else
    dlmwrite(strcat(strcat(folder,'Matter2',fullFileName(end-7:end-4),'.txt')), Matter2,'delimiter', '\t', 'newline', 'pc');
end;


% Matter1