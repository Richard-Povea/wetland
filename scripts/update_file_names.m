function update_file_names(class, outputPath)
    files_path = sprintf('.\\mediaData\\%s', class);
    files = dir(files_path);
    if ~exist('outputPath', "var")
        outputPath = files_path;
    end
    i = 1;
    for file = {files.name}
        if length(file{:}) < 5
            continue
        end
        path = sprintf('%s\\%s',files_path,file{:});
        output_path = sprintf('%s\\%s%03d.wav',outputPath,class,i);
        movefile(path, output_path)
        i = i+1;
    end
end