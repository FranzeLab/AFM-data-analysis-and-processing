function ShowImage(I)    % by Julia Becker, 01/04/2020, additions 27/04/2021 concerning maximising
imshow(I);
axis image
hold on;
set(gcf, 'WindowState','maximized');        % to display properly maximized
%set(gcf, 'Position', get(0, 'Screensize')); % old version, somewhat slightly bigger than maximized on some screens?
end

