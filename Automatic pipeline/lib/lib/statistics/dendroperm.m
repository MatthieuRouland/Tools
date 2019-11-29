function perm = dendroperm(Z,varargin)
%DENDROGRAM Generate dendrogram plot.
%   DENDROGRAM(Z) generates a dendrogram plot of the hierarchical binary
%   cluster tree represented by Z.  Z is an (M-1)-by-3 matrix, generated by
%   the LINKAGE function, where M is the number of objects in the original
%   dataset.
%
%   A dendrogram consists of many U-shaped lines connecting objects in a
%   hierarchical tree.  The height of each U represents the distance
%   between the two objects being connected.  If there were 30 or fewer
%   data points in the original dataset, each leaf in the dendrogram
%   corresponds to one data point.  If there were more than 30 data points,
%   the complete tree can look crowded, and DENDROGRAM collapses lower
%   branches as necessary, so that some leaves in the plot correspond to
%   more than one data point.
%
%   DENDROGRAM(Z,P) generates a dendrogram with no more than P leaf nodes,
%   by collapsing lower branches of the tree.  To display the complete
%   tree, set P = 0. The Default value of P is 30.
%
%   H = DENDROGRAM(...) returns a vector of line handles.
%
%   [H,T] = DENDROGRAM(...) generates a dendrogram and returns T, a vector
%   of size M that contains the leaf node number for each object in the
%   original dataset.  T is useful when P is less than the total number of
%   objects, so some leaf nodes in the display correspond to multiple
%   objects.  For example, to find out which objects are contained in leaf
%   node k of the dendrogram, use find(T==k). When there are fewer than P
%   objects in the original data, all objects are displayed in the
%   dendrogram.  In this case, T is the identity map, i.e., T = (1:M)',
%   where each node contains only a single object.
%
%   [H,T,OUTPERM] = DENDROGRAM(...) generates a dendrogram and returns a
%   vector of the node labels of the leaves shown in the dendrogram,
%   ordered from left to right on a horizontal dendrogram and bottom to
%   top for a vertical dendrogram. OUTPERM is a permutation of the vector
%   1:P, where P is the number of nodes shown.
%   
%   [ ... ] = DENDROGRAM(..., 'PARAM1',val1, 'PARAM2',val2, ...) specifies
%   optional parameter name/value pairs:
%  
%      'Reorder'         - A numeric vector PERM representing the requested
%                          ordering of the nodes in the complete tree,
%                          ordered from left to right on a horizontal
%                          dendrogram and bottom to top for a vertical
%                          dendrogram. PERM must be a permutation of the
%                          vector 1:M. 
%
%      'CheckCrossing'   - A logical value defining whether to check if
%                          PERM will cause crossing branches in the plot.
%                          It's only useful when the 'Reorder' option is
%                          provided. Default is true. If true, a warning
%                          will be issued if PERM causes crossing branches
%                          in the plot. When the dendrogram doesn't draw
%                          the complete tree, a warning won't be given if
%                          PERM causes crossing branches in the complete
%                          tree but not in the dendrogram shown in the plot.
%
%      'ColorThreshold'  - A threshold T. Dendrogram assigns a unique color
%                          to each group of nodes within the dendrogram
%                          whose linkage is less than T. Values are:
%                            * A string 'default'. T will be set to 70% of
%                              the maximum linkage i.e. 0.7 * max(Z(:,3)).
%                            * A numerical scalar in the range of
%                              0 < T < max(Z(:,3)). If T is not given, or
%                              T is less than or equal to zero, or T is
%                              greater than the maximum linkage then the
%                              dendrogram will be drawn using only one
%                              color.
%
%      'Orientation'     - A string that orients the dendrogram within the
%                          figure window. Values are:
%                            * 'top'      -- top to bottom (default)
%                            * 'bottom'   -- bottom to top
%                            * 'left'     -- left to right
%                            * 'right'    -- right to left
%
%      'Labels'          - A character array or cell array strings S with
%                          one label for each observation. Any leaves in
%                          the tree containing a single observation are
%                          labeled with that observation's label.
%
%   Example:
%      X = rand(100,2);
%      Y = pdist(X,'cityblock');
%      Z = linkage(Y,'average');
%      [H, T] = dendrogram(Z);
%   
%      rng('default')
%      X=rand(10,3);
%      Z=linkage(X,'ave');
%      % Draw the dendrogram using the default setting
%      subplot(2,1,1); dendrogram(Z);
%      % Reorder the nodes shown in the plot. 
%      subplot(2,1,2); dendrogram(Z,'reorder',[ 9 5 8 10 2 4 1 6 7 3 ]);
%
%   See also LINKAGE, PDIST, CLUSTER, CLUSTERDATA, COPHENET, INCONSISTENT,
%   SILHOUETTE.

%   Copyright 1993-2011 The MathWorks, Inc.


numLeaves = size(Z,1)+1; %the number of observations

if nargin < 2
    p = 30;
end

if nargin == 2
    p = varargin{1};
    
end

color = false;
orientation = 't'; %default top
obslabels = [];
threshold = 0.7 * max(Z(:,3));
leafOrder = [];
horz = false;

if nargin > 2
    if isnumeric(varargin{1})
        p = varargin{1};
        offset = 1;
          
    else
        p = 30;
        offset = 0;
    end
    
    pnames = {'orientation' 'colorthreshold' 'labels'  'reorder','checkcrossing'};
    dflts =  {orientation   'default'        obslabels leafOrder, true};
    [orientation,threshold,obslabels,leafOrder,check,setFlag] =  ...
        internal.stats.parseArgs(pnames, dflts, varargin{1+offset:end});
    
    if ~isscalar (check) || ~islogical (check)
         error(message('stats:dendrogram:BadCheck'));
    end
    
    if ~isempty(orientation) && ischar(orientation)
        orientation = lower(orientation(1));
    else
        orientation = 0;    % bad value
    end
    
    if  orientation == 0 || ~ismember(orientation,{'t','b','r','l'}) 
        orientation = 't';
        warning(message('stats:dendrogram:BadOrientation'));
    end
    horz = ismember(orientation,{'r','l'});
    
    color = setFlag.colorthreshold; % threshold argument was given
    if color
        if ischar(threshold) && strncmpi(threshold,'default',length(threshold))
            threshold = 0.7 * max(Z(:,3));
        elseif ~isnumeric(threshold)
            error(message('stats:dendrogram:BadThreshold'));
        end
    end
    
    if ~isempty(obslabels)
        if ischar(obslabels)
            obslabels = cellstr(obslabels);
        elseif ~iscellstr(obslabels)
            error(message('stats:dendrogram:BadLabels'));
        end
        if ~isvector(obslabels) || numel(obslabels) ~= numLeaves
            error(message('stats:dendrogram:InputSizeMismatch'));
        end
        obslabels = obslabels(:);
    end
    
    if ~isempty(leafOrder)
        if (~isvector(leafOrder) || numel(leafOrder)~=numLeaves )
            error(message('stats:dendrogram:BadLeafOrder'));
        else
            leafOrder = leafOrder(:)'; %make it to be a row vector
            if ~isequal(sort(leafOrder),1:numLeaves)
                error(message('stats:dendrogram:BadLeafOrder'));
            end
        end
    end
end

if ~isscalar(p) || p < 0 || p == 1
            error(message('stats:dendrogram:BadP'));
end    

% For each node currently labeled numLeaves+k, replace its index by
% min(i,j) where i and j are the nodes under node numLeaves+k.
Z = transz(Z);
T = (1:numLeaves)'; 

% If there are more than p nodes, the dendrogram looks crowded.
% The following code will make the last p link nodes into leaf nodes,
% and only these p nodes will be visible.
if (numLeaves > p) && (p ~= 0)
    
    Y = Z((numLeaves-p+1):end,:);         % get the last nodes
    
    R = unique(Y(:,1:2));
    Rlp = R(R<=p);
    Rgp = R(R>p);
    W(Rlp) = Rlp;                 % use current node number if <=p
    W(Rgp) = setdiff(1:p, Rlp);   % otherwise get unused numbers <=p
    W = W(:);
    T(R) = W(R);
    
    % Assign each leaf in the original tree to one of the new node numbers
    for i = 1:p
        c = R(i);
        T = clusternum(Z,T,W(c),c,numLeaves-p+1,0); % assign to its leaves.
    end
    
    % Create new, smaller tree Z with new node numbering
    Y(:,1) = W(Y(:,1));
    Y(:,2) = W(Y(:,2));
    % At this point, it's possible that Z(i,1) < Z(i,i) for some rows.
    %The newly formed cluster will always be represented by the number in Z(i,1);
    Z = Y; 
    
    %Assign each leaf in the leafOrder to one of the new node numbers.
    if ~isempty(leafOrder)
        leafOrder = T(leafOrder)';
        d = diff(leafOrder);
        d = [1 d];
        leafOrder = leafOrder (d~=0);
        if numel(leafOrder) ~= p
            error(message('stats:dendrogram:InvalidLeafOrder'));
        end       
    end
    
    numLeaves = p; % reset the number of nodes to be p (row number = p-1).
end

A = zeros(4,numLeaves-1);
B = A;
X = 1:numLeaves; %the initial points for observation 1:n
Y = zeros(numLeaves,1);

if isempty(leafOrder)
    r = Y;
    % arrange Z into W so that there will be no crossing in the dendrogram.
    W = zeros(size(Z));
    W(1,:) = Z(1,:);
    
    nsw = zeros(numLeaves,1); rsw = nsw;
    nsw(Z(1,1:2)) = 1; rsw(1) = 1;
    k = 2; s = 2;
    
    while (k < numLeaves)
        i = s;
        while rsw(i) || ~any(nsw(Z(i,1:2)))
            if rsw(i) && i == s
                s = s+1;
            end
            i = i+1;
        end
        
        W(k,:) = Z(i,:);
        nsw(Z(i,1:2)) = 1;
        rsw(i) = 1;
        if s == i
            s = s+1;
        end
        k = k+1;
    end
    
    % initialize X based on W
    g = 1;
    for k = 1:numLeaves-1
        i = W(k,1); %the left node in W(k,:)
        if ~r(i),
            X(i) = g;
            g = g+1;
            r(i) = 1;
        end
        i = W(k,2); %the right node in W(k,:)
        if ~r(i),
            X(i) = g;
            g = g+1;
            r(i) = 1;
        end
    end
    perm(X) = 1:numLeaves;
    
else % ~isempty(leafOrder) if a leaf order is specified use
    %get X based on the specified order
    X(leafOrder) = 1:numLeaves;
    %need to check whether leafOrder will have crossing branch
    if (check)
       checkCrossing(Z(:,[1 2]), leafOrder);
    end
    perm = leafOrder;
end


% label = num2str(perm');
% if ~isempty(obslabels)
%     label = cellstr(label);
%     % label(:) = {''};   % to make sure non-singletons get an empty label
%     singletons = find(histc(T,1:numLeaves)==1);
%     for j=1:length(singletons)
%         sj = singletons(j);
%         label(perm==sj) = obslabels(T==sj);
%     end
% end
% % set up the color
% 
% theGroups = 1;
% groups = 0;
% cmap = [0 0 1];
% 
% if color
%     groups = sum(Z(:,3)< threshold);
%     if groups > 1 && groups < (numLeaves-1)
%         theGroups = zeros(numLeaves-1,1);
%         numColors = 0;
%         for count = groups:-1:1
%             if (theGroups(count) == 0)
%                 P = zeros(numLeaves-1,1);
%                 P(count) = 1;
%                 P = colorcluster(Z,P,Z(count,1),count);
%                 P = colorcluster(Z,P,Z(count,2),count);
%                 numColors = numColors + 1;
%                 theGroups(logical(P)) = numColors;
%             end
%         end
%         cmap = hsv(numColors);
%         cmap(end+1,:) = [0 0 0];
%     else
%         groups = 1;
%     end
%     
% end
% 
% 
% if  isempty(get(0,'CurrentFigure')) || ishold
%     if strcmp(get(0,'DefaultFigureWindowStyle'),'normal')
%         figure('Position', [50, 50, 800, 500]);
%     else
%         figure;
%     end
% else
%     newplot;
% end
% 
% col = zeros(numLeaves-1,3);
% h = zeros(numLeaves-1,1);
% 
% for n = 1:(numLeaves-1)
%     i = Z(n,1); j = Z(n,2); w = Z(n,3);
%     A(:,n) = [X(i) X(i) X(j) X(j)]';
%     B(:,n) = [Y(i) w w Y(j)]';
%     X(i) = (X(i)+X(j))/2; Y(i)  = w;
%     if n <= groups
%         col(n,:) = cmap(theGroups(n),:);
%     else
%         col(n,:) = cmap(end,:);
%     end
% end
% 
% ymin = min(Z(:,3));
% ymax = max(Z(:,3));
% margin = (ymax - ymin) * 0.05;
% n = size(label,1);
% 
% if(~horz)
%     for count = 1:(numLeaves-1)
%         h(count) = line(A(:,count),B(:,count),'color',col(count,:));
%     end
%     lims = [0 numLeaves+1 max(0,ymin-margin) (ymax+margin)];
%     set(gca, 'Xlim', [.5 ,(n +.5)], 'XTick', 1:n, 'XTickLabel', label, ...
%         'Box', 'off');
%     mask = logical([0 0 1 1]);
%     if strcmp(orientation,'b')
%         set(gca,'XAxisLocation','top','Ydir','reverse');
%     end
% else
%     for count = 1:(numLeaves-1)
%         h(count) = line(B(:,count),A(:,count),'color',col(count,:));
%     end
%     lims = [max(0,ymin-margin) (ymax+margin) 0 numLeaves+1 ];
%     set(gca, 'Ylim', [.5 ,(n +.5)], 'YTick', 1:n, 'YTickLabel', label, ...
%         'Box', 'off');
%     mask = logical([1 1 0 0]);
%     if strcmp(orientation, 'l')
%         set(gca,'YAxisLocation','right','Xdir','reverse');
%     end
% end
% 
% if margin==0
%     if ymax~=0
%         lims(mask) = ymax * [0 1.25];
%     else
%         lims(mask) = [0 1];
%     end
% end
% axis(lims);
% if nargout>0
%     hout = h;
% end

% ---------------------------------------
function T = clusternum(X, T, c, k, m, d)
% assign leaves under cluster c to c.

d = d+1;
n = m; flag = 0;
while n > 1
    n = n-1;
    if X(n,1) == k % node k is not a leave, it has subtrees
        T = clusternum(X, T, c, k, n,d); % trace back left subtree
        T = clusternum(X, T, c, X(n,2), n,d);
        flag = 1; break;
    end
end

if flag == 0 && d ~= 1 % row m is leaf node.
    T(X(m,1)) = c;
    T(X(m,2)) = c;
end
% ---------------------------------------
function T = colorcluster(X, T, k, m)
% find local clustering

n = m;
while n > 1
    n = n-1;
    if X(n,1) == k % node k is not a leave, it has subtrees
        T = colorcluster(X, T, k, n); % trace back left subtree
        T = colorcluster(X, T, X(n,2), n);
        break;
    end
end
T(m) = 1;
% ---------------------------------------
function Z = transz(Z)
%TRANSZ Translate output of LINKAGE into another format.
%   This is a helper function used by DENDROGRAM and COPHENET.

%   In LINKAGE, when a new cluster is formed from cluster i & j, it is
%   easier for the latter computation to name the newly formed cluster
%   min(i,j). However, this definition makes it hard to understand
%   the linkage information. We choose to give the newly formed
%   cluster a cluster index M+k, where M is the number of original
%   observation, and k means that this new cluster is the kth cluster
%   to be formed. This helper function converts the M+k indexing into
%   min(i,j) indexing.

numLeaves = size(Z,1)+1;

for i = 1:(numLeaves-1)
    if Z(i,1) > numLeaves
        Z(i,1) = traceback(Z,Z(i,1));
    end
    if Z(i,2) > numLeaves
        Z(i,2) = traceback(Z,Z(i,2));
    end
    if Z(i,1) > Z(i,2)
        Z(i,1:2) = Z(i,[2 1]);
    end
end


function a = traceback(Z,b)

numLeaves = size(Z,1)+1;

if Z(b-numLeaves,1) > numLeaves
    a = traceback(Z,Z(b-numLeaves,1));
else
    a = Z(b-numLeaves,1);
end
if Z(b-numLeaves,2) > numLeaves
    c = traceback(Z,Z(b-numLeaves,2));
else
    c = Z(b-numLeaves,2);
end

a = min(a,c);


function checkCrossing(Z, order)
%check whether the give Tree will have crossing branches with the given
%permutation vector

numBranches = size(Z,1);
numLeaves = numBranches + 1;
%numLabels = numBranches + numLeaves;
% reorder the tree
perm = order(:);
%XPos is the position indices for leaves 1:numLeaves. 
XPos(perm) = 1:numLeaves;
Z0 = Z; %keep the original tree
%renumber the leave nodes in Z such that number N represents the Nth nodes
%in the plot
Z = XPos(Z);

% Check if the reordered tree structure leads to a tree with no crossing branches
minPos = 1:numLeaves;
maxPos = 1:numLeaves;
sz = ones(numLeaves,1);

for i = 1:numBranches
    currentMinPos = min(minPos(Z(i,:)));
    currentMaxPos = max(maxPos(Z(i,:)));
    currentSize = sum(sz(Z(i,:)));
    if currentMaxPos - currentMinPos + 1 ~= currentSize 
        warning(message('stats:dendrogram:CrossingBranches'));
        break;
    end
    
    j =XPos(Z0(i,1));% j is the cluster number for the newly formed cluster.
    %Note that we can't use j = XPos(min(Z0(i,:))), Because when not all of
    % the points are shown, the value in the first column of Z may be bigger
    % than the value in the second column.
    minPos(j)= currentMinPos;
    maxPos(j) = currentMaxPos;
    sz(j) = currentSize;
    
end

