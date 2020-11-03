function S = gui_to_checkSpecificity(scanFile, S, channelCy, channelDapi)

    % set default thresholds to use:
    threshold_min = 0.0;
    threshold_max = 1.0;
    
    reader = bfGetReader(scanFile);
      
    barcodeFISHnonempty = cellfun(@(x) ~isempty(x.coords), {S.barcodeFISH},'UniformOutput',true);
    barcodeFISHpositions = find(barcodeFISHnonempty ==1);
    
    for i = 1:numel(barcodeFISHpositions)
        if ~isfield(S(barcodeFISHpositions(i)).barcodeFISH,'label')
            S(barcodeFISHpositions(i)).barcodeFISH.label = true(1,numel(S(barcodeFISHpositions(i)).barcodeFISH.coords));
        end
    end
    frame = 1;
    
%     fields = fieldnames(barcodeFISHPoints(position));
%     if isempty(fields)
%         barcodeFISHPoints(position).nuclei = [];
%         barcodeFISHPoints(position).coordinates = [];
%         
%         barcodeFISHPoints(imageCountN).nuclei = [];
%         barcodeFISHPoints(imageCountN).coordinates = [];
%     end
    
    % create GUI:
    handles = create_GUI;
    
    % make the figure larger;
    set(handles.figure, ...
        'Units', 'normalized', ...
            'Position', [0, 0, .5, .9]);
        
    % move gui to the center of the screen:
    movegui(handles.figure, 'center');
    
    % view image:
    view_image;
    
    % function to create GUI:
    function handles = create_GUI
        
        % set sizes:
        margin = 0.01;
        image_height = 0.6;
        
        figure_start_x = 0;
        figure_start_y = 0;
        figure_width = 1;
        figure_height = 1;
        
        width_full = figure_width - 2*margin;
        width_half = (width_full - margin)/2;
        width_third = (width_full - margin)/3;
        height_all = (figure_height - image_height - 6*margin)/5;
        
        image_start_x = margin;
        image_start_y = margin;
        image_width = width_full;
        
        contrast_lower_start_x = margin;
        contrast_lower_start_y = image_start_y + image_height + margin;
        contrast_lower_width = width_full;
        contrast_lower_height = height_all;
        
        contrast_upper_start_x = margin;
        contrast_upper_start_y = contrast_lower_start_y + height_all + margin;
        contrast_upper_width = width_full;
        contrast_upper_height = height_all;
               
        add_start_x = margin;
        add_start_y = contrast_upper_start_y + height_all + margin;
        add_width = width_third;
        add_height = height_all;
        
        clear_start_x = add_start_x + width_third + margin;
        clear_start_y = add_start_y;
        clear_width = width_third;
        clear_height = height_all;
        
        done_start_x = clear_start_x + width_third + margin;
        done_start_y = add_start_y;
        done_width = width_third;
        done_height = height_all;
        
        previous_start_x = margin;
        previous_start_y = add_start_y + height_all + margin;
        previous_width = width_third;
        previous_height = height_all;
        
        next_start_x = previous_start_x + width_third + margin;
        next_start_y = previous_start_y;
        next_width = width_third;
        next_height = height_all;
        
        position_start_x = next_start_x + width_third + margin;
        position_start_y = previous_start_y;
        position_width = width_third;
        position_height = height_all;
        
        instructions_start_x = margin;
        instructions_start_y = position_start_y + height_all + margin;
        instructions_width = width_full;
        instructions_height = height_all;
        
        % create figure:
        handles.figure = figure('Units', 'normalized', ...
            'Position', [figure_start_x, figure_start_y, figure_width, figure_height]);
        
        % add image:
        handles.image = axes('Units', 'normalized', ...
            'Position', [margin, margin, image_width, image_height]);
        
        % add button to adjust lower end of contrast:
        handles.contrast_lower = uicontrol('Style', 'slider', ...
            'Units', 'normalized', ...
            'Position', [contrast_lower_start_x, contrast_lower_start_y, contrast_lower_width, contrast_lower_height], ...
            'Callback', @callback_contrast_lower, ...
            'min', 0, 'max', 1, 'Value', 0);
        
        % add button to adjust upper end of contrast:
        handles.contrast_upper = uicontrol('Style', 'slider', ...
            'Units', 'normalized', ...
            'Position', [contrast_upper_start_x, contrast_upper_start_y, contrast_upper_width, contrast_upper_height], ...
            'Callback', @callback_contrast_upper, ...
            'min', 0, 'max', 1, 'Value', 1);
        
        % add button to add points:
        handles.add = uicontrol('Style', 'pushbutton', ...
            'Units', 'normalized', ...
            'Position', [add_start_x, add_start_y, add_width, add_height], ...
            'String', 'Add', ...
            'FontSize', 18, ...
            'Callback', @callback_add);
        
        % add button to clear points:
        handles.clear = uicontrol('Style', 'pushbutton', ...
            'Units', 'normalized', ...
            'Position', [clear_start_x, clear_start_y, clear_width, clear_height], ...
            'String', 'Clear', ...
            'FontSize', 18, ...
            'Callback', @callback_clear);
        
        % add button to move to pevious image:
        handles.previous = uicontrol('Style', 'pushbutton', ...
            'Units', 'normalized', ...
            'Position', [previous_start_x, previous_start_y, previous_width, previous_height], ...
            'String', 'Previous', ...
            'FontSize', 18, ...
            'Callback', @callback_previous);
        
        % add button to move to next image:
        handles.next = uicontrol('Style', 'pushbutton', ...
            'Units', 'normalized', ...
            'Position', [next_start_x, next_start_y, next_width, next_height], ...
            'String', 'Next', ...
            'FontSize', 18, ...
            'Callback', @callback_next);
        
        % add button to move to next image:
        handles.position = uicontrol('Style', 'edit', ...
            'Units', 'normalized', ...
            'Position', [position_start_x, position_start_y, position_width, position_height], ...
            'String', string(GFPpositions(1)), ...
            'FontSize', 18, ...
            'Callback', @callback_position);
        
        % add button to be done:
        handles.done = uicontrol('Style', 'pushbutton', ...
            'Units', 'normalized', ...
            'Position', [done_start_x, done_start_y, done_width, done_height], ...
            'String', 'Done', ...
            'FontSize', 18, ...
            'Callback', @callback_done);
        
        % add instructions:
        uicontrol('Style', 'text', ...
            'Units', 'normalized', ...
            'Position', [instructions_start_x, instructions_start_y, instructions_width, instructions_height], ...
            'FontSize', 26, ...
            'String', 'Click add to select false positive cells: barcodeFISH+ (yellow or red circle), GFP-(no green circle). Be sure to press Enter before moving to Next frame. Yellow circle indicates true positive, red indicates false positive');
        
    end



    % function to view the image:
    function view_image
        
        reader.setSeries(GFPpositions(frame)-1);
        iPlane = reader.getIndex(0, channelCy-1, 0) + 1;
        tmpPlaneCy  = bfGetPlane(reader, iPlane);
        tmpPlaneCy = imadjust(im2double(tmpPlaneCy), [threshold_min, threshold_max]); 
        
        iPlane = reader.getIndex(0, channelDapi-1, 0) + 1;
        tmpPlaneDapi  = bfGetPlane(reader, iPlane);
        tmpPlaneDapi = scale(im2double(tmpPlaneDapi)); 
        
        RGB = cat(3, tmpPlaneCy, tmpPlaneCy, tmpPlaneCy+tmpPlaneDapi);
        
        % display the image:
        imshow(RGB, 'Parent', handles.image);
        
        % plot barcode FISH:
        plot_FISH;
        
        % plot GFP:
        plot_GFP;
        
        % have program wait:
        uiwait(handles.figure);
        
    end


% callback to move to previous image in scan:
    function callback_next(~, ~)
         
        if frame+1 == numel(GFPpositions)
            callback_done
        else
            frame = frame + 1;
            
            handles.position.String = string(GFPpositions(frame));
            
        end
        
        % view image:
        view_image;

    end

% callback tomove to next image in scan:
    function callback_previous(~, ~)
         
        if frame > 1
            
            frame = frame - 1;
            
            handles.position.String = string(GFPpositions(frame));
        end
        
        % view image:
        view_image;

    end

% callback tomove to next image in scan:
    function callback_position(~, ~)
        
        user_position = get(handles.position, 'String');
        
        if user_position < 1
            
            frame = 1;
            handles.position.String = string(GFPpositions(frame));
        elseif user_position > numel(GFPpositions)
            frame = numel(GFPpositions);
            handles.position.String = string(GFPpositions(frame));
        else
            frame = str2double(user_position);
        end
            
        % view image:
        view_image;

    end

  % function to plot the points:
    function plot_FISH

                % turn on the hold:
        hold(handles.image, 'on'); 

        % get coordinates:
        temp_coords = cell2mat(S(barcodeFISHpositions(frame)).barcodeFISH.coords);
%             temp_coords = [S(GFPpositions(frame)).barcodeFISH.coords];
%             temp_coords = reshape(temp_coords, 2, []);
%             temp_coords = temp_coords';

        temp_labels = S(barcodeFISHpositions(frame)).barcodeFISH.label;
        
        % plot true positives yellow:
        scatter(temp_coords(temp_labels,1), temp_coords(temp_labels,2), 80, 'yellow');  

        % plot false negative red:
        scatter(temp_coords(~temp_labels,1), temp_coords(~temp_labels,2), 80, 'red'); 
            
        % turn off the hold:
        hold(handles.image, 'off'); 
        
    end

    % function to plot the points:
    function plot_GFP
        % turn on the hold:
        hold(handles.image, 'on'); 
        
        % get coordinates:
        temp_coords = cell2mat(S(barcodeFISHpositions(frame)).GFP.coords);
%         temp_coords = [S(GFPpositions(frame)).GFP.coords];
%         temp_coords = reshape(temp_coords, 2, []);
%         temp_coords = temp_coords';
                
        % plot true positives green:
        scatter(temp_coords(:,1), temp_coords(:,2), 36, 'filled', 'green');  

        % turn off the hold:
        hold(handles.image, 'off'); 
        
        
    end

    % function to adjust lower bound of contrast:
    function callback_contrast_lower(~,~)
        
        % get the slider value:
        threshold_min = get(handles.contrast_lower, 'Value');
        
        % show the image:
        view_image
        
    end

    % function to adjust upper bound of contrast:
    function callback_contrast_upper(~,~)
        
        % get the slider value:
        threshold_max = get(handles.contrast_upper, 'Value');
        
        % show the image:
        view_image;
        
    end

    % callback to add points:
    function callback_add(~, ~)
            
        % allow user to select points:
        [x,y] = getpts(handles.image);

        % find corresponding points in S.GFP
        temp_coords = cell2mat(S(barcodeFISHpositions(frame)).barcodeFISH.coords);
%         temp_coords = [S(GFPpositions(frame)).GFP.coords];
%         temp_coords = reshape(temp_coords, 2, []);
%         temp_coords = temp_coords';
        
        nearnessThreshold = 10; %Finds nearest spot within this distance. If none found, then does nothing. 
        
        I = findNearest(temp_coords, [x,y], nearnessThreshold);
        

        %Set labels to false
        temp_labels = S(barcodeFISHpositions(frame)).barcodeFISH.label;
        
        temp_labels(I) = false;
        
        S(barcodeFISHpositions(frame)).barcodeFISH.label = temp_labels;
        % view image:
        view_image;

    end

    % callback to reset labels to true:
    function callback_clear(~, ~)
        
        S(barcodeFISHpositions(frame)).barcodeFISH.label = true(1,numel(S(barcodeFISHpositions(frame)).barcodeFISH.coords));

        % view the image:
        view_image;
        
    end

    % callback to be done:
    function callback_done(~,~)
        
        % close the GUI:
        close(handles.figure);
        
    end

end