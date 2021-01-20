function S = gui_to_selectGFPPositive_v2(S, tileSize,channelGFP, channelDAPI)

    % set default image contrast to use:
    threshold_min = 0;
    threshold_max = 1;
    
    % Divide stitch into chunks. Get origin for each chunk. Adjust by ~5%
    % for slight overlap
    top_starts = (1:(tileSize(2)*0.95):size(S.stitches{1},2));
    left_starts = (1:(tileSize(1)*0.95):size(S.stitches{1},1));

    n_row=numel(left_starts); 
    n_col=numel(top_starts); 

    top_coords=repmat(top_starts,n_row, 1);
    top_coords=top_coords(:)';

    left_coords=repmat(top_starts,1,n_col);
    left_coords=left_coords(:)';
    
    frame = 1;
    Nframes = numel(left_coords); 
    reveal = false;
        
    if ~isfield(S.nuclei,'GFP')
         S.nuclei.GFP = false(1,numel(S.nuclei.coords));
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
        image_height = 0.8;
        
        figure_start_x = 0;
        figure_start_y = 0;
        figure_width = 1;
        figure_height = 1;
        
        width_full = figure_width - 2*margin;
        width_half = (width_full - margin)/2;
        width_third = (width_full - margin)/3;
        width_quarter = (width_full - margin)/4;
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
        add_width = width_quarter;
        add_height = height_all;
        
        clear_start_x = add_start_x + width_quarter + margin;
        clear_start_y = add_start_y;
        clear_width = width_quarter;
        clear_height = height_all;
        
        reveal_start_x = clear_start_x + width_quarter + margin;
        reveal_start_y = add_start_y;
        reveal_width = width_quarter;
        reveal_height = height_all;
        
        done_start_x = reveal_start_x + width_quarter + margin;
        done_start_y = add_start_y;
        done_width = width_quarter;
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
        
        % add button to show barcodePositive points:
        handles.clear = uicontrol('Style', 'pushbutton', ...
            'Units', 'normalized', ...
            'Position', [reveal_start_x, reveal_start_y, reveal_width, reveal_height], ...
            'String', 'Reveal', ...
            'FontSize', 18, ...
            'Callback', @callback_reveal);
        
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
            'String', string(frame), ...
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
            'FontSize', 16, ...
            'String', 'Click add to select barcode positive cells. Be sure to press Enter before moving to Next frame');
        
    end



    % function to view the image:
    function view_image
        
        border =  cat(2, [left_coords(frame),  top_coords(frame)], tileSize);

        tmpPlaneGFP  = imcrop(S.stitches{channelGFP}, border);
        tmpPlaneGFP = imadjust(im2double(tmpPlaneGFP), [threshold_min, threshold_max]); 
        
        tmpPlaneDapi  = imcrop(S.stitches{channelDAPI}, border);
        tmpPlaneDapi = scale(im2double(tmpPlaneDapi)); 
        
        RGB = cat(3, tmpPlaneGFP, tmpPlaneGFP, tmpPlaneGFP+tmpPlaneDapi);
        
        % display the image:
        imshow(RGB, 'Parent', handles.image);
        
        % plot point:
        plot_nuclei(border);
        
        % plot point:
        plot_points(border);
        
        % plot point:
        if reveal
            plot_reveal(border);
        end
        
        
        % have program wait:
        uiwait(handles.figure);
        
    end


% callback to move to previous image in scan:
    function callback_next(~, ~)
         
        if frame+1 == Nframes
            callback_done
        else
            frame = frame + 1;
            
            handles.position.String = string(frame);
            
        end
        
        % view image:
        view_image;

    end

% callback tomove to next image in scan:
    function callback_previous(~, ~)
         
        if frame > 1
            
            frame = frame - 1;
            
            handles.position.String = string(frame);
        end
        
        % view image:
        view_image;

    end

% callback tomove to next image in scan:
    function callback_position(~, ~)
        
        user_position = get(handles.position, 'String');
        user_position = str2double(user_position);
        
        if user_position < 1
            
            frame = 1;
            handles.position.String = string(frame);
        elseif user_position > Nframes
            frame = Nframes;
            handles.position.String = string(frame);
        else
            frame = user_position;
        end
            
        % view image:
        view_image;

    end

  % function to plot the points:
    function plot_nuclei(border)
        
        rectangle = bbox2points(border);
        %Find nuclei within frame, Probably a better way to do this but
        %this works...
        temp_coords = cell2mat(S.nuclei.coords);
%         leftX = left_coords(frame);
%         rightX = left_coords(frame) + tileSize(1);
%         topY = top_coords(frame);
%         bottomY = top_coords(frame) + tileSize(2);
        inFrameNuclei = inpolygon(temp_coords(:,1), temp_coords(:,2), rectangle(:,1), rectangle(:,2));
        
        inFrameNucleiCoords = temp_coords(inFrameNuclei, :);
        inFrameNucleiCoords = inFrameNucleiCoords - rectangle(1,:); %convert global to local coords
        
        % turn on the hold:
        hold(handles.image, 'on'); 
        
        % plot coordinates on image:
        scatter(inFrameNucleiCoords(:,1), inFrameNucleiCoords(:,2), 20, 'yellow', 'filled');      
        
        % turn off the hold:
        hold(handles.image, 'off'); 
        
    end

    % function to plot the points:
    function plot_points(border)
        
        if any(S.nuclei.GFP)
            %Only plot barcodeFISH positive points
            temp_label = S.nuclei.GFP;
            temp_coords = cell2mat(S.nuclei.coords(temp_label));

            %Find nuclei within frame, Probably a better way to do this but
            %this works...
            rectangle = bbox2points(border);
    %         leftX = left_coords(frame);
    %         rightX = left_coords(frame) + tileSize(1);
    %         topY = top_coords(frame);
    %         bottomY = top_coords(frame) + tileSize(2);
            inFrameNuclei = inpolygon(temp_coords(:,1), temp_coords(:,2), rectangle(:,1), rectangle(:,2));

            inFrameNucleiCoords = temp_coords(inFrameNuclei, :);
            inFrameNucleiCoords = inFrameNucleiCoords - rectangle(1,:); %convert global to local coords

            % turn on the hold:
            hold(handles.image, 'on'); 

            % plot coordinates on image:
            scatter(inFrameNucleiCoords(:,1), inFrameNucleiCoords(:,2), 20, 'green', 'filled');      

            % turn off the hold:
            hold(handles.image, 'off'); 
        end
        
    end

    function plot_reveal(border)
        
        if any(S.nuclei.barcodeFISH)
            %Only plot barcodeFISH positive points
            temp_label = S.nuclei.barcodeFISH;
            temp_coords = cell2mat(S.nuclei.coords(temp_label));

            %Find nuclei within frame, Probably a better way to do this but
            %this works...
            rectangle = bbox2points(border);
    %         leftX = left_coords(frame);
    %         rightX = left_coords(frame) + tileSize(1);
    %         topY = top_coords(frame);
    %         bottomY = top_coords(frame) + tileSize(2);
            inFrameNuclei = inpolygon(temp_coords(:,1), temp_coords(:,2), rectangle(:,1), rectangle(:,2));

            inFrameNucleiCoords = temp_coords(inFrameNuclei, :);
            inFrameNucleiCoords = inFrameNucleiCoords - rectangle(1,:); %convert global to local coords

            % turn on the hold:
            hold(handles.image, 'on'); 

            % plot coordinates on image:
            scatter(inFrameNucleiCoords(:,1), inFrameNucleiCoords(:,2), 80, 'red');      

            % turn off the hold:
            hold(handles.image, 'off'); 
        end
        
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
        
        %Adjust local coord to global 
        selectedPoints = [x,y] +  [left_coords(frame), top_coords(frame)];

        % find corresponding points in S.GFP
        nuclei_coords = cell2mat(S.nuclei.coords);
        
        nearnessThreshold = 10; %Finds nearest spot within this distance. If none found, then does nothing. 
        
        I = findNearest(nuclei_coords, selectedPoints, nearnessThreshold);
        
        %Set labels true
        temp_labels = S.nuclei.GFP;
        
        temp_labels(I) = true;
        
        S.nuclei.GFP = temp_labels;
        % view image:
        view_image;

    end

    % callback to delete a segmentation:
    function callback_clear(~, ~)
        
        border =  cat(2, [left_coords(frame),  top_coords(frame)], tileSize);
        rectangle = bbox2points(border);
        
        %Reset nuclei in frame
        temp_coords = cell2mat(S.nuclei.coords);
%         leftX = left_coords(frame);
%         rightX = left_coords(frame) + tileSize(1);
%         topY = top_coords(frame);
%         bottomY = top_coords(frame) + tileSize(2);
        inFrameNuclei = inpolygon(temp_coords(:,1), temp_coords(:,2), rectangle(:,1), rectangle(:,2));
        
         %Set labels false
        temp_labels = S.nuclei.GFP;
        
        temp_labels(inFrameNuclei) = false;
        
        S.nuclei.GFP = temp_labels;
        % view image:
        view_image;
        
    end

    % callback to delete a segmentation:
    function callback_reveal(~, ~)
        
        reveal = not(reveal);
        % view image:
        view_image;
        
    end

    % callback to be done:
    function callback_done(~,~)
        
        % close the GUI:
        close(handles.figure);
        
    end

end