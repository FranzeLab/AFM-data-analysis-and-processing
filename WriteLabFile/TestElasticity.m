
[FileName,PathName,FilterIndex] = uigetfile({'*.out;*.txt','potential force curves'},'Select curve','C:\ac563\work\measurementdata\test\','MultiSelect','on')

[rawdata,headerinfo] = Readfile(PathName,FileName)


vv = headerinfo{1}
size(vv)
x=cell2str(vv(10))
y=cell2str(vv(11))
str2num(x(16:end-3))
str2num(y(16:end-3))
 v=rawdata{1};
 size(v)

[Labbook_file,Labbook_path] = uigetfile('*.txt','Labbookfile',...
    PathName,'MultiSelect','off');
LabbookFileName = [Labbook_path Labbook_file];

openLabbook = fopen(LabbookFileName);
Labbook = textscan (openLabbook, '%s %f %f %f');
fclose(openLabbook);

Labbook{1}