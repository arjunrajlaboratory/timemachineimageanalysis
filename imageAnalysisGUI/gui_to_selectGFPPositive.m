function S = gui_to_selectGFPPositive(scanFile, S, channelGFP, channelDapi)

    % set default thresholds to use:
    threshold_min = 0.0;
    threshold_max = 1.0;
    
    reader = bfGetReader(scanFile);
    omeMeta = reader.getMetadataStore();        
    imageCountN = omeMeta.getImageCount();
    position = 1;
    
    %fields = fieldnames(S(position))
    if ~isfield(S(position),'nuclei')
        [S(1:imageCountN).nuclei] = deal(struct('coords', []));
    end
    
    if ~isfield(S(position),'GFP')
         [S(1:imageCountN).GFP] = deal(struct('coords', []));
    end
   
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
            'String', string(position), ...
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
            'String', 'Click add to select GFP positive cells. Be sure to press Enter before moving to Next frame');
        
    end



    % function to view the image:
    function view_image
        
        reader.setSeries(position-1);
        iPlane = reader.getIndex(0, channelGFP-1, 0) + 1;
        tmpPlaneGFP  = bfGetPlane(reader, iPlane);
        tmpPlaneGFP = imadjust(im2double(tmpPlaneGFP), [threshold_min, threshold_max]); 
        
        iPlane = reader.getIndex(0, channelDapi-1, 0) + 1;
        tmpPlaneDapi  = bfGetPlane(reader, iPlane);
        tmpPlaneDapi = scale(im2double(tmpPlaneDapi)); 
        
        RGB = cat(3, tmpPlaneGFP, tmpPlaneGFP, tmpPlaneGFP+tmpPlaneDapi);
        
        % display the image:
        imshow(RGB, 'Parent', handles.image);
        
        % plot point:
        plot_nuclei;
        
        % plot point:
        plot_points;
        
        %For testing, plot barcode FISH points
%         plot_FISH
        
        % have program wait:
        uiwait(handles.figure);
        
    end


% callback to move to previous image in scan:
    function callback_next(~, ~)
         
        if position+1 == imageCountN
            callback_done
        else
            position = position + 1;
            
            handles.position.String = string(position);
            
        end
        
        % view image:
        view_image;

    end

% callback tomove to next image in scan:
    function callback_previous(~, ~)
         
        if position > 1
            
            position = position - 1;
            
            handles.position.String = string(position);
        end
        
        % view image:
        view_image;

    end

% callback tomove to next image in scan:
    function callback_position(~, ~)
        
        user_position = get(handles.position, 'String');
        
        if user_position < 1
            
            position = 1;
            handles.position.String = string(position);
        elseif user_position > imageCountN
            position = imageCountN;
            handles.position.String = string(position);
        else
            position = str2double(user_position);
        end
            
        % view image:
        view_image;

    end

  % function to plot the points:
    function plot_nuclei
        
%         if ~isfield(S(position).nuclei, 'coords')
%             S(position).nuclei.coords = [];
%         end
        
        if isempty([S(position).nuclei.coords])
            iPlane = reader.getIndex(0, channelDapi-1, 0) + 1;
            tmpPlaneDapi  = bfGetPlane(reader, iPlane);
            tmpPlaneDapi = scale(im2uint16(tmpPlaneDapi)); 

            image_binarize= imbinarize(tmpPlaneDapi, adaptthresh(tmpPlaneDapi, 0.1, 'ForegroundPolarity','bright'));

            CC = bwconncomp(image_binarize, 4);

            rp = regionprops(CC);

            area = [rp.Area];
            centroids = [rp.Centroid];
            centroids = reshape(centroids,2,[])'; 
            centroids = round(centroids); 

            idx = area > 200; % Get rid of small stuff

            temp_coords = centroids(idx, 1:end);
            
            % save coords:
            coords2save = num2cell(temp_coords, 2);
        
            S(position).nuclei.coords = coords2save;
       else
            temp_coords = cell2mat(S(position).nuclei.coords);
%             temp_coords = reshape(temp_coords, 2, []);
%             temp_coords = temp_coords';
       end
        
        % turn on the hold:
        hold(handles.image, 'on'); 
        
        % plot coordinates on image:
        scatter(temp_coords(:,1), temp_coords(:,2), 20, 'yellow', 'filled');      
        
        % turn off the hold:
        hold(handles.image, 'off'); 
        
    end

    % function to plot the points:
    function plot_points
        
        if ~isempty([S(position).GFP.coords])
            % turn on the hold:
            hold(handles.image, 'on'); 
            
            % get coordinates:
            temp_coords = cell2mat(S(position).GFP.coords);
%             temp_coords = reshape(temp_coords, 2, []);
%             temp_coords = temp_coords';

            % plot coordinates on image:
            scatter(temp_coords(:,1), temp_coords(:,2), 20, 'red', 'filled');
            
            % turn off the hold:
            hold(handles.image, 'off'); 
            
        end
        
    end

% For testing
%     function plot_FISH
%         
%         if ~isempty([S(position).barcodeFISH.coords])
%             % turn on the hold:
%             hold(handles.image, 'on'); 
%             
%             % get coordinates:
%             temp_coords = cell2mat(S(position).barcodeFISH.coords);
%             temp_coords = reshape(temp_coords, 2, []);
%             temp_coords = temp_coords';
% 
%             % plot coordinates on image:
%             scatter(temp_coords(:,1), temp_coords(:,2), 80, 'black');
%             
%             % turn off the hold:
%             hold(handles.image, 'off'); 
%             
%         end
%         
%     end

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

        % save coords:
        temp_coords = num2cell([x,y], 2);
        
        S(position).GFP.coords = temp_coords;

        % view image:
        view_image;

    end

    % callback to delete a segmentation:
    function callback_clear(~, ~)
        
        if ~isempty([S(position).GFP.coords])
            
            [S(position).GFP] = deal(struct('coords', []));

        end

        % view the image:
        view_image;
        
    end

    % callback to be done:
    function callback_done(~,~)
        
        % close the GUI:
        close(handles.figure);
        
    end

end