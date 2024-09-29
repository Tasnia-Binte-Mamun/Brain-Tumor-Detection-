function J=regiongrowing(I,x,y,reg_maxdist)

if(exist('reg_maxdist','var')==0), reg_maxdist=0.2; end

J = zeros(size(I)); % Output 
Isizes = size(I); % Dimensions of input image

reg_mean = I(x,y); % The mean of the segmented region
reg_size = 1; % Number of pixels in region

% Free memory to store neighbours of the (segmented) region
neg_free = 10000; neg_pos=0;  %Current position of neighbour
neg_list = zeros(neg_free,3); 

%    Column 1: xn - the x-coordinate of the pixel
%    Column 2: yn - the y-coordinate of the pixel
%    Column 3: The intensity value of the pixel at coordinates (xn, yn)
pixdist=0; % Distance of the region newest pixel to the region mean
%ntensity difference between the mean intensity value of the current region
%and a potential new pixel

% Neighbor locations (footprint)
neigb=[-1 0; 1 0; 0 -1;0 1];  
%neigb defines four possible neighboring positions around a central point:

 %   One step to the right.
 %   One step to the left.
 %   One step down.
 %   One step up.

% Start regiogrowing until distance between regio and posible new pixels become
% higher than a certain treshold
while(pixdist<reg_maxdist&&reg_size<numel(I))

    % Add new neighbors pixels
    for j=1:4,
        % Calculate the neighbour coordinate
        xn = x +neigb(j,1); yn = y +neigb(j,2);
        
        % Check if neighbour is inside or outside the image
        ins=(xn>=1)&&(yn>=1)&&(xn<=Isizes(1))&&(yn<=Isizes(2));
        
        % Add neighbor if inside and not already part of the segmented area
        if(ins&&(J(xn,yn)==0)) 
                neg_pos = neg_pos+1;
                neg_list(neg_pos,:) = [xn yn I(xn,yn)]; J(xn,yn)=1;
        end
    end
     
    % Add pixel with intensity nearest to the mean of the region, to the region
    dist = abs(neg_list(1:neg_pos,3)-reg_mean);
    [pixdist, index] = min(dist);
    J(x,y)=2; reg_size=reg_size+1;
    
    % Calculate the new mean of the region
    reg_mean= (reg_mean*reg_size + neg_list(index,3))/(reg_size+1);
    
    % Save the x and y coordinates of the pixel (for the neighbour add proccess)
    x = neg_list(index,1); y = neg_list(index,2);
    
    % Remove the pixel from the neighbour (check) list
    neg_list(index,:)=neg_list(neg_pos,:); neg_pos=neg_pos-1;
end

% Return the segmented area as logical matrix
J=J>1;




