function pathfile = pathfile(taxonomy)
    taxonomies = {'frog', 'bird', 'dog', 'vehicle', 'step', 'murmullo', 'rain',  'wind'};
    selected_taxonomy = taxonomies{taxonomy};
    base_path = 'D:\mediaData';
    taxonomy_path = sprintf('%s%s%s',base_path,'\', selected_taxonomy);
    n_files = size(dir(taxonomy_path),1)-1;
    pathfile = sprintf('%s%s%s%03d.wav', taxonomy_path, '\', selected_taxonomy, randi(n_files));
end