clc
close all
clear all

%% Input
[I,path]=uigetfile('*.jpg','select a input image');
str=strcat(path,I);
s=imread(str);

figure; subplot 221;
imshow(s);
title('Input image');

%% Converting to Grayscale

inp=imresize(s,[256,256]);
if size(inp,3)>1
    inp=rgb2gray(inp);
end
subplot 222;
imshow(inp); title('Converted Gray Scale image')

%% Contrast Enhancement

inp_con_enhance= histeq(inp);
subplot 223;
imshow(inp_con_enhance); title('Contrast Enhanced');

%enhancement using high pass filter

p= padding(size(inp_con_enhance));
F= fft2(inp_con_enhance,p(1),p(2));

D0=0.005*p(1);
w= lp_filter('butterworth',p(1),p(2),D0,20);
hp_w= 1-w;

filtered= hp_w.*F;
filtered_img= real(ifft2(filtered));
filtered_img= filtered_img(1:size(inp,1),1:size(inp,2));

subplot 224;
imshow(filtered_img,[]); title('High pass Filtered');

%% Edge detection

%Sobel
filtered_sobel= edge_detection(inp,"sobel");
figure
subplot 221;
imshow(inp); title('Input image');
subplot 222;
imshow(filtered_sobel,[]); title('Sobel filtered');

%Prewitt
filtered_prewitt= edge_detection(inp,"prewitt");
subplot 223;
imshow(filtered_prewitt,[]); title('Prewitt filtered');

%Canny

filtered_canny= edge_detection(inp,"canny");
subplot 224;
imshow(filtered_canny,[]); title('Canny filtered');

%% Filtering

% Median filter
N= imnoise(inp,'salt & pepper',0.01); %Adding noise

filtered_noise= medfilt2(N,[3 3],'symmetric');  %filtered using symmetric padding

figure
subplot 121;
imshow(N,[]); title('Noisy input image');
subplot 122;
imshow(filtered_noise,[]); title('Filtered image');

%% Creating mask of tumor using Manual Segmentation

thresh= thresh_tool(uint16(inp_con_enhance),'gray');
bw= inp_con_enhance>240;

% Morphological operation

bw= imfill(bw,'holes');
nhood= strel('disk',3);
bw1= imopen(bw, nhood);

label=bwlabel(bw1);
stats=regionprops(label,'Solidity','Area','BoundingBox');
density=[stats.Solidity];
area=[stats.Area];
high_dense_area=density>0.85;
max_area=max(area(high_dense_area));
tumor_label=find(area==max_area);
tumor=ismember(label,tumor_label);

if max_area>1000
   figure;
   subplot 221;
   imshow(inp); title('Input image');
   subplot 222;
   imshow(tumor); 
   title('Mask of Tumor');
else
    h = msgbox('No Tumor!!','status');
    return;
end

%% Creating mask of tumor using Region growing 

% read image
reg_maxdist = 0.2;
I = im2double(inp);
figure
%subplot 221;
imshow(I); title("Input image");
% let the user pick one point
[y,x] = ginput(1);
% round to integer to match required input by regiongrowing function
x = round(x);
y = round(y);
% plot point on original image
hold on;
plot(y,x,'xg','MarkerSize',20,'LineWidth',2);
hold off;
% get region from seed point
tumor = regiongrowing(I,x,y,reg_maxdist);
% plot region
%subplot 222;
figure
imshow(tumor); title('Mask of Tumor');

%% Getting Tumor Outline - image filling, eroding, subtracting
% erosion the walls by a few pixels

nhood= ones(5,5);
erodedImage= imerode(tumor,nhood);
tumorOutline=tumor;
tumorOutline(erodedImage)=0;

% Inserting the outline in input image in red color

rgb = inp(:,:,[1 1 1]);
red = rgb(:,:,1);
red(tumorOutline)=255;
green = rgb(:,:,2);
green(tumorOutline)=0;
blue = rgb(:,:,3);
blue(tumorOutline)=0;

tumorOutlineInserted(:,:,1) = red; 
tumorOutlineInserted(:,:,2) = green; 
tumorOutlineInserted(:,:,3) = blue; 

subplot 223;
imshow(tumorOutlineInserted);
title('Detected Tumor');


%% Bounding box

box = stats(tumor_label);
wantedBox = box.BoundingBox;
subplot 224;
imshow(tumorOutlineInserted);
title('Adding Bounding Box');
hold on;
rectangle('Position',wantedBox,'EdgeColor','y','LineWidth',3);
hold off;
%% k means clustering

wd=256;
Input=imresize(inp,[256 256]);
Input(tumor)=255;
figure(1);
imshow(Input); title('Input image');
[r,c]   = size(Input);

Input   =double(Input);
Length = (r*c); 
Dataset = reshape(Input,[Length,1]);

Clusters=4; %k CLUSTERS
Cluster1=zeros(Length,1);
Cluster2=zeros(Length,1);
Cluster3=zeros(Length,1);
Cluster4=zeros(Length,1);

% Step 1: sets up initial centroids evenly distributed across the range...
% of input intensity values.

miniv = min(min(Input));
maxiv = max(max(Input));
range = maxiv - miniv;
stepv = range/Clusters;
incrval = stepv;
for i = 1:Clusters
    K(i).centroid = incrval;
    incrval = incrval + stepv;
end

update1=0;
update2=0;
update3=0;
update4=0;

mean1=2;
mean2=2;
mean3=2;
mean4=2;

while  ((mean1 ~= update1) & (mean2 ~= update2) & (mean3 ~= update3) & (mean4 ~= update4))
   
   % Step 4: Repeat steps 2 and 3 until the centroid "k" does not change.
   mean1=K(1).centroid;
   mean2=K(2).centroid;
   mean3=K(3).centroid;
   mean4=K(4).centroid;

   % Step 2: Assign each pixel to the kth point that has the closest...
   % centroid as per their Euclidean distance.
   for i=1:Length
       for j = 1:Clusters
           temp= Dataset(i);
           difference(j) = abs(temp-K(j).centroid);
       end
       [y,ind]=min(difference);
       if ind==1
          Cluster1(i)=temp;
       end
       if ind==2
          Cluster2(i)=temp;
       end
       if ind==3
          Cluster3(i)=temp;
       end
       if ind==4
          Cluster4(i)   =temp;
       end
  end
  
  %Step 3: The K's position is recalculated.
  %UPDATE CENTROIDS
  cout1=0;
  cout2=0;
  cout3=0;
  cout4=0;

  for i=1:Length
           
       if Cluster1(i) ~= 0
          cout1=cout1+1;
       end
       if Cluster2(i) ~= 0
          cout2=cout2+1;
       end
       if Cluster3(i) ~= 0
           cout3=cout3+1;
       end
       if Cluster4(i) ~= 0
           cout4=cout4+1;
       end
  end

  Mean_Cluster(1)=sum(Cluster1)/cout1;
  Mean_Cluster(2)=sum(Cluster2)/cout2;
  Mean_Cluster(3)=sum(Cluster3)/cout3;
  Mean_Cluster(4)=sum(Cluster4)/cout4;

  %reload
  for i = 1:Clusters
      K(i).centroid = Mean_Cluster(i);
  end
  
  update1=K(1).centroid;
  update2=K(2).centroid;
  update3=K(3).centroid;                                  
  update4=K(4).centroid;

  end

%Step 5: Display each divided cluster separately to view k number of clusters.
AA1=reshape(Cluster1,[wd wd]);
AA2=reshape(Cluster2,[wd wd]);
AA3=reshape(Cluster3,[wd wd]);
AA4=reshape(Cluster4,[wd wd]);

figure
subplot 141;
imshow(AA1); title('Cluster 1');
subplot 143;
imshow(AA2); title('Cluster 3');
subplot 142;
imshow(AA3); title('Cluster 2');
subplot 144;
imshow(AA4); title('Cluster 4');

%imtool(inp)

%% k means clustering

wd=256;
inp(tumor)=255;
Input=imresize(inp,[256 256]);
figure(1);
imshow(Input);
[r,c,p]   = size(Input);
if p==3
   Input= Input(:,:,2);
   figure(2);
   imshow(Input);
   Input = imadjust(Input,[0.4 0.8],[]);
   figure(3);
   imshow(Input);
end

Input   =double(Input);
Length = (r*c); 
Dataset = reshape(Input,[Length,1]);  % Flattening image

Clusters=4; 
Cluster= zeros(Length,4);

% Step 1: sets up initial centroids evenly distributed across the range...
% of input intensity values.

miniv = min(min(Input));
maxiv = max(max(Input));
range = maxiv - miniv;
stepv = range/Clusters;
incrval = stepv;

for i = 1:Clusters
    K(i).centroid = incrval;
    incrval = incrval + stepv;
end

for i= 1:Clusters
   update(i)=0;
   mean(i)=2;  % Assigning mean a random value 
end

% Step 4: Repeat steps 2 and 3 until the centroid "k" does not change.
convergence = false;
while ~convergence

    for i=1: Cluster
           mean(i)=K(i).centroid;
    end
    convergence = true;
    for i = 1:length(mean)
        if mean(i) ~= update(i)
            convergence = false;
            break;
        end
    end
    
    if ~convergence                
       % Step 2: Assign each pixel to the kth point that has the closest...
       % centroid as per their Euclidean distance.

       for i=1:Length
           for j = 1:Clusters
                temp= Dataset(i);
                difference(j) = abs(temp-K(j).centroid); 
           end

           [y,ind]=min(difference)
           Cluster(i,ind)=temp; 
       end

  %Step 3: The K's position is recalculated.
  %UPDATE CENTROIDS
      for i=1:Clusters
          cout(i)=0;
      end
 
      for i=1:Clusters
          for j=1:Length             
             if Cluster(j,i)~= 0
                 cout(1,i)=cout(1,i)+1;
             end
          end
      end
 
   for i=1:Clusters
         Mean_Cluster(i)=sum(Cluster(i,:))/cout(1,i); %Mean of data points within the cluster
         K(i).centroid = Mean_Cluster(i);
         update(i)=K(i).centroid;
   end
  end
end

AA= zeros(256,256,Clusters);

%Step 5: Display each divided cluster separately to view k number of clusters.

for i=1:Cluster
   AA(:,:,i)=reshape(Clusters(:,i),[wd wd]);
end

figure
subplot 141;
imshow(AA(:,:,1)); title('Cluster 1');
subplot 143;
imshow(AA(:,:,2)); title('Cluster 3');
subplot 142;
imshow(AA(:,:,3)); title('Cluster 2');
subplot 144;
imshow(AA(:,:,4)); title('Cluster 4');

