clear all

[FileName,PathName,FilterIndex] = uigetfile({'*.out;*.txt','potential force curves'},'Select curve','MultiSelect','on');
% if data sets are larger than 600, the files need to be split using the
% following lines:
%[FileName2,PathName2,FilterIndex2] = uigetfile({'*.out;*.txt','potential force curves'},'Select curve','MultiSelect','on');
%FileName=[FileName FileName2];

filename = strcat(PathName, FileName);
[headerinfo, Size] = getheader (filename);

%FF = cell(Size,5)
%M(1:Size,1:5)=0;
for i=1:Size
    FF{i,1} = FileName{i}(end-11:end-4);
    dd = headerinfo{i};
    vv = dd{1};
    x = cell2str(vv(10));
    y = cell2str(vv(11));
    FF{i,2} = str2num(x(16:end-3));
    FF{i,3} = str2num(y(16:end-3));
    FF{i,4} = 0;
% this used to be in  FF{i,5} = 0;
end;

GG=FF.';

fid = fopen(strcat(PathName,'\LabFile.txt'), 'wt');
fprintf(fid, '%s\t%e\t%e\t%e\n', GG{:});
fclose(fid);
% fwritecell('LabFile.txt','%s \t %e \t %e \t %f',FF);

%t = cell2mat({' '})
%fid = fopen('LabFile.txt','a+');
%fseek('LabFile.txt',0,'bof');
%fwrite(fid,'Hallo');
%fclose(fid);



%dlmwrite('LabFile.txt', t,'delimiter', '\t', 'newline', 'pc');

%fid = fopen('LabFile.txt', 'w');
%for row=1:Size
%    fprintf(fid, '%s %f %f %f \n', FF{row,:});
%end
% 

%dlmwrite('LabFile.txt', FF,'delimiter', '\t', 'newline', 'pc');

%size(vv)
%x=cell2str(vv(10))
%y=cell2str(vv(11))