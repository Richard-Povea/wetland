function overwrite = confirm_overwrite()
    global RECIEVER
    csv_path = sprintf('\\Data_generated\\final_data_table_%s.csv', RECIEVER);
    if exist(csv_path, 'file') %Verificar si ya hay un archivo csv guardado
        fig = uifigure;
        msg = 'Saving these changes will overwrite previous changes.';
        title = 'Confirm Save';
        selection = uiconfirm(fig,msg,title, ...
                   'Options',{'Overwrite','Concatenate values','Cancel'}, ...
                   'DefaultOption',2,'CancelOption',3);
        switch selection
            case 'Overwrite'
                overwrite = true;
            case 'Concatenate values'
                overwrite = false;
            case 'Cancel'
                error('Canceled by user, csv file not saved.')
        end
        close(fig);
        return
    end
    overwrite = true;
end