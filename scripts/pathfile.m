function pathfile = pathfile(taxonomy, skip)

     if ~exist('skip','var')
         % third parameter does not exist, so default it to something
          skip = true;
     end

    global RNG myStream %#ok<GVMIS> 
    taxonomies = {'frog', 'bird', 'dog', 'vehicle', 'step', 'murmullo', 'rain',  'wind'};
    selected_taxonomy = taxonomies{taxonomy};
    base_path = 'D:\mediaData';
    taxonomy_path = sprintf('%s%s%s',base_path,'\', selected_taxonomy);
    n_files = size(rdir(taxonomy_path),1)-1;

    if skip
        myStream.Substream = RNG;
        RNG = RNG+1;
    end 

    random = randi(n_files);
   
    pathfile = sprintf('%s\\%s%03d.wav', taxonomy_path, selected_taxonomy, random);
end