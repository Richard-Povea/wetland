function pathfile = pathfile(taxonomy, skip)

     if ~exist('skip','var')
         % third parameter does not exist, so default it to something
          skip = true;
     end

    global RNG myStream %#ok<GVMIS> 

    taxonomy_path = sprintf('.\\mediaData\\%s', taxonomy);
    n_files = size(dir(taxonomy_path),1)-2;

    if skip
        myStream.Substream = RNG;
        RNG = RNG+1;
    end 

    random = randi(n_files);
   
    pathfile = sprintf('%s\\%s%03d.wav', taxonomy_path, taxonomy, random);
end