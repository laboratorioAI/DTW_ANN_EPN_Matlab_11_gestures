classdef recognitionModel
    %UNTITLED12 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        user
        version
        gesture
        options
        numLabels
        dataX
        dataY
        numNeuronsLayers 
        transferFunctions
        
    end
    
    methods
        function obj = recognitionModel(user,version,gesture,options)
            
            obj.user = user;
            obj.version = version;
            obj.gesture = gesture;
            obj.options = options;
            obj.numLabels = length(obj.gesture);
            obj.numNeuronsLayers = [length(gesture) length(gesture) length(gesture)];
            obj.transferFunctions{1} = 'none'; % Input
            obj.transferFunctions{2} = 'tanh'; % Hidden
            obj.transferFunctions{3} = 'softmax'; % Output
             
 
        end
           
        
        
       function [X, Y] = getTotalXnYByUser(obj)

            % =========================================================
            % Determinar tipo de muestras
            % =========================================================
        
            if strcmpi(obj.version, 'training')
        
                gestureType = 'trainingSamples';
        
            elseif strcmpi(obj.version, 'testing')
        
                gestureType = 'testingSamples';
        
            else
        
                error('Version debe ser "training" o "testing".');
        
            end
        
            gestureData = obj.user.(gestureType);
        
            % Número real de muestras
            numSamples = length(fieldnames(gestureData));
        
            % Número real de clases
            numClasses = length(obj.gesture);
        
            fprintf( ...
                'Procesando %d muestras correspondientes a %d clases...\n', ...
                numSamples, ...
                numClasses);
        
            % Inicializar
            X = cell(1, numClasses);
            Y = cell(1, numClasses);
        
            % =========================================================
            % TRAINING
            %
            % En training tenemos gestureName, por lo que agrupamos
            % directamente según la clase real.
            % =========================================================
        
            if strcmpi(obj.version, 'training')
        
                for kRep = 1:numSamples
        
                    rep = sprintf('idx_%d', kRep);
        
                    % -------------------------------------------------
                    % Leer EMG
                    % -------------------------------------------------
        
                    emgData = gestureData.(rep).emg;
        
                    EMG = [];
        
                    for ch = 1:8
        
                        channel = sprintf('ch%d', ch);
        
                        EMG(:,ch) = ...
                            emgData.(channel) / 128;
        
                    end
        
                    [samples, ~] = size(EMG);
        
                    % -------------------------------------------------
                    % Obtener clase según gestureName
                    % -------------------------------------------------
        
                    code = codeSamples(kRep, gestureData);
        
                    % -------------------------------------------------
                    % Agregar la señal a su clase correspondiente
                    % -------------------------------------------------
        
                    X{code}{end + 1} = EMG;
        
                    Y{code}{end + 1} = ...
                        repmat(code, samples, 1);
        
                end
        
            % =========================================================
            % TESTING
            %
            % El JSON de testing no tiene gestureName.
            % Por tanto se conserva la organización por bloques.
            % =========================================================
        
            elseif strcmpi(obj.version, 'testing')
        
                x = cell(1, numSamples);
        
                for kRep = 1:numSamples
        
                    rep = sprintf('idx_%d', kRep);
        
                    emgData = gestureData.(rep).emg;
        
                    EMG = [];
        
                    for ch = 1:8
        
                        channel = sprintf('ch%d', ch);
        
                        EMG(:,ch) = ...
                            emgData.(channel) / 128;
        
                    end
        
                    x{kRep} = EMG;
        
                end
        
                % -----------------------------------------------------
                % Comprobar que las muestras se puedan distribuir
                % uniformemente entre las clases
                % -----------------------------------------------------
        
                if mod(numSamples, numClasses) ~= 0
        
                    error( ...
                        ['El número de muestras de testing (%d) no es ', ...
                         'divisible para el número de clases (%d).'], ...
                         numSamples, ...
                         numClasses);
        
                end
        
                numTrialsPerClass = numSamples / numClasses;
        
                fprintf( ...
                    'Testing: %d repeticiones por clase.\n', ...
                    numTrialsPerClass);
        
                % Organizar muestras por clase
                data = reshape( ...
                    x, ...
                    numTrialsPerClass, ...
                    numClasses ...
                )';
        
                for class_i = 1:numClasses
        
                    X{class_i} = data(class_i,:);
        
                end
        
            end
        
        end
        
       
       function X = getTotalXnYByUserTest(obj)
       % This function reads the time series (X) and the labels (Y) of the user
       % "username", stored in the forlder "pathname", corresponding to "training"
       % or "testing" (i.e., value of variable "version") and the gestures 
       % indicated in the cell "gestures"
            
       
            if (strcmp('training',obj.version) == 1)

                sampleType = 'trainingSamples';

            elseif (strcmp('testing',obj.version) == 1)

                sampleType = 'testingSamples';

            end

            gestureData = obj.user.(sampleType);
            numTrialsForEachGesture = length(fieldnames(gestureData));
 

            for i_emg = 1:numTrialsForEachGesture

                sampleNum = sprintf('sample%d',i_emg);
                emgSample = gestureData.(sampleNum).emg;

                EMG = [];

                    for ch = 1:8               
                        channel = sprintf('ch%d',ch); 
                        EMG(:,ch) = (emgSample.(channel))/128;
                    end

                [samples, ~] = size(EMG);
                % GET X

                x{i_emg} = EMG;

            end

            data = reshape(x,[],25);

            for column = 1:6

                X{column} = data(column,:);

            end

       
        end
       
       
     
        
        function emg_out = preProcessEMG(obj,emg_in)
        % This function pre-process an EMG by applying normalization to tne range
        % [-1, 1] if needed, rectification, low-pass filtering, and segmentation of
        % the region of the EMG corresponding to a muscle contraction    
            
            options = obj.options;
   
            Fa = options.Fa;
            Fb = options.Fb;
            rectFcn = options.rectFcn;
            plotSignals = options.plotSignals;
            numClasses = length(emg_in);
            emg_out = emg_in;
            for class_i = 1:numClasses
                raw_emg_class_i = emg_in{class_i};
                numTrials_class_i = length(raw_emg_class_i);
                filtered_emg_class_i = raw_emg_class_i;
                for trial_j = 1:numTrials_class_i
                    raw_emg_class_i__trial_j = raw_emg_class_i{trial_j};
                    filteredEMG = preProcessEMGSegment(raw_emg_class_i__trial_j, Fa, Fb, rectFcn);

                    if options.Segmentation
                        % This part of the code performs segmentation
                        % Parameters for EMG segmentation
                        FaSegmentation = options.FaSegmentation;
                        FbSegmentation = options.FbSegmentation;
                        rectFcnSegmentation = options.rectFcnSegmentation;
                        filtEMG = preProcessEMGSegment(raw_emg_class_i__trial_j,...
                            FaSegmentation, FbSegmentation, rectFcnSegmentation);
                        [idxStart, idxEnd] = detectMuscleActivity(filtEMG, options);
                    else
                        % If the segmentation is not used
                        idxStart = 1;
                        idxEnd = size(filteredEMG, 1);
                    end
                    filtered_emg_class_i{trial_j} = filteredEMG(idxStart:idxEnd, :);
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                    if plotSignals
                        figure(3);
                        f = gcf;
                        set(f, 'Name', ['Class: ' num2str(class_i) ', Trial: ' num2str(trial_j)]);
                        numChannels = size(raw_emg_class_i__trial_j, 2);
                        for c = 1:numChannels
                            subplot(4, 2, c);
                            if max( abs(raw_emg_class_i__trial_j(:, c)) ) > 1
                                raw_emg_class_i__trial_j(:, c) = raw_emg_class_i__trial_j(:, c)/128;
                            end
                            plot(raw_emg_class_i__trial_j(:, c), 'r');
                            hold all;
                            plot(filteredEMG(:, c), 'k');
                            plot([1 idxStart idxStart idxEnd idxEnd size(raw_emg_class_i__trial_j, 1)],...
                                [0 0 1 1 0 0], 'b', 'linewidth', 2);
                            hold off;
                            ylim([-1 1]);
                            title(['CH: ' num2str(c)]);
                        end
                        hold off;
                        drawnow;
                        figure(4);
                        f = gcf;
                        set(f, 'Name', ['Class: ' num2str(class_i) ', Trial: ' num2str(trial_j)]);
                        subplot(2, 1, 1);
                        imagesc(raw_emg_class_i__trial_j', [-1, 1]);
                        colormap jet;
                        colorbar;
                        title('Raw EMG');
                        subplot(2, 1, 2);
                        imagesc(filteredEMG', [-1, 1]);
                        colormap jet;
                        colorbar;
                        title('Filtered EMG');
                        drawnow;
                        fprintf('Press ENTER to continue\n');
                        pause;
                    end
                    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                end
                emg_out{class_i} = filtered_emg_class_i;
            end

        end 
        
        
        
        function [train_XOut, trainYOut] = makeSingleSet(obj,train_XIn, train_YIn)
        % This function puts the EMGs of each class from the set train_XIn in a 
        % single set train_XOut. Additionally, this function also puts in single
        % vector trainYOut the labels from the set train_YIn

            numClasses = size(train_XIn, 2);
            numTrialsPerClass = size(train_XIn{1}, 2);
            numSamples = numClasses*numTrialsPerClass;
            train_XOut = cell(numSamples, 1); trainYOut = nan(numSamples, 1);
            cont = 0;
            for class_i = 1:numClasses
                numTrials_class_i = size(train_XIn{class_i}, 2);
                train_XIn_class_i = train_XIn{class_i};
                train_YIn_class_i = train_YIn{class_i};
                for trial_j = 1:numTrials_class_i
                    trainXIn_class_i_trial_j = train_XIn_class_i{trial_j};
                    trainYIn_class_i_trial_j = train_YIn_class_i{trial_j};

                    cont = cont + 1;
                    train_XOut{cont, 1} = trainXIn_class_i_trial_j;
                    trainYOut(cont, 1) = mode(trainYIn_class_i_trial_j);
                end
            end
            train_XOut = train_XOut(1:cont, 1); 
            trainYOut = trainYOut(1:cont, 1);
        end
       
        
        
        function centers = findCentersOfEachClass(obj, timeSeries, dataY)
        % This function returns a set of time series called centers. The ith
        % time series of centers, centers{i}, is the center of the cluster of time 
        % series from the set timeSeries that belong to the ith class. For finding
        % the center of each class, the DTW distance is used.
            
            options = obj.options;
            
            numTimeSeries = length(timeSeries);
            listOfSeries = 1:numTimeSeries;
            classes = unique(dataY);
            numClasses = length(classes);
            centers = cell(1, numClasses);
            w = options.dtwWindow;
            for class_i = 1:numClasses
                idxSeries_class_i = listOfSeries(dataY == class_i);
                numIdxSeries_class_i = length(idxSeries_class_i);
                mtxDistances_class_i = zeros(numIdxSeries_class_i, numIdxSeries_class_i);
                for serie_j = 1:numIdxSeries_class_i
                    serie_class_i_idx_j = timeSeries{ idxSeries_class_i(serie_j) };
                    for serie_k = 1:numIdxSeries_class_i
                        serie_class_i_idx_k = timeSeries{ idxSeries_class_i(serie_k) };
                        if serie_k > serie_j
                            dist = dtw_c( serie_class_i_idx_j, serie_class_i_idx_k, w );
                            mtxDistances_class_i(serie_j, serie_k) = dist;
                            mtxDistances_class_i(serie_k, serie_j) = dist;
                        end
                    end
                end
                vectDistances_class_i = sum(mtxDistances_class_i);
                [dummy, idx] = min(vectDistances_class_i);
                centerIdx = idxSeries_class_i(idx);
                centers{class_i} = timeSeries{ centerIdx };
            end
        end
        
        
        
        
        function plotClusters(timeSeries, clusters, centers)
        % This function plots the clusters generated from a set of time series
        %
        % Inputs:
        %
        %        - timeSeries: [Nx1] cell, where each element of the cell is a time
        %                      serie
        %          - clusters: [Nx1] vector containing the number of group to which
        %                      each element of the cell timeSeries belongs to. Each
        %                      element of this vector is a number in the set
        %                      {1, 2, ...,c}, where c denotes the number of
        %                      clusters
        %           - centers: [1*c] cell containing the indices in the cell timeSeries
        %                      of the series that act as center of each cluster

            numTimeSeries = length(timeSeries);
            listOfSeries = 1:numTimeSeries;
            numCols = 2;
            numClusters = length(centers);
            numRows = ceil(numClusters/numCols);
            for cluster_i = 1:numClusters
            IdxSeries_cluster_i = listOfSeries(clusters == cluster_i);
            numSeries_cluster_i = length(IdxSeries_cluster_i);
            for serie_j = 1:numSeries_cluster_i
                cluster_i_serie_j = timeSeries{IdxSeries_cluster_i(serie_j)};
                numChannels = size(cluster_i_serie_j, 2);
                for channel_k = 1:numChannels
                    figure(channel_k);
                    set(gcf, 'Name', ['Channel ' num2str(channel_k),...
                        '. Cluster centers are drawn with a ticker line']);
                    subplot(numCols, numRows, cluster_i);
                    plot(cluster_i_serie_j(:, channel_k), 'linewidth', 1);
                    ylim([-1, 1]);
                    if serie_j == 1
                        hold all;
                    end
                    title(['Cluster ' num2str(cluster_i)])
                end
            end
            numChannels = size( centers{cluster_i}, 2);
            for channel_k = 1:numChannels
                figure(channel_k);
                subplot(numCols, numRows, cluster_i);
                hold all;
                plot(centers{cluster_i}(:, channel_k), 'linewidth', 2);
            end
            end
            hold off;
            drawnow;
        end
        
        
        
        
        function dataX = featureExtraction(obj, timeSeries, centers)
        % This function computes a feature vector for each element from the set
        % timeSeries. The dimension of this feature vector depends on the number of 
        % time series of the set centers. The value of the jth feature of the ith
        % vector in dataX corresponds to the DTW distance between the signals 
        % timeSeries{i} and centers{j}.           
            
            options = obj.options;    
            numTimeSeries = length(timeSeries);
            numClusters = length(centers);
            w = options.dtwWindow;
            dataX = nan(numTimeSeries, numClusters);
            for serie_i = 1:numTimeSeries
                timeSerie_i = timeSeries{ serie_i };
                for center_j = 1:numClusters
                    center_cluster_j = centers{ center_j };
                    distance = dtw_c( timeSerie_i, center_cluster_j, w );
                    dataX(serie_i, center_j) = distance;
                end
            end
        end

        
        
        function struct = preProcessFeatureVectors(obj, dataX_in)
        % This function preprocess each feature vector of the set dataX_in. Each
        % row of dataX_in is a fetaure vector and each column is a feature.
        % The preprocessing that can be applied to a feature vector include the 
        % following options:
        %
        % vector:   Standardizes the values of a vector
        % feature:  Standardizes the features of a set of vectors
        % minmax:   Normalizes the features by subtracting the minimum and dividing
        %           by the maximum of each feature
        % none:     No pre-processing of the feature vectors
        
            metaParameters =obj.options;
            typePreprocessing = metaParameters.typePreprocessingFeatVector;
            if strcmpi(typePreprocessing, 'vector')
                numExamples = size(dataX_in, 1);
                dataX_mean = zeros(numExamples, 1);
                dataX_std = zeros(numExamples, 1);
                for i = 1:numExamples
                    dataX_mean(i) = mean( dataX_in(i, :) );
                    dataX_std(i) = std( dataX_in(i,:) );
                end
                numFeatures = size(dataX_in, 2);
                struct.dataX = ( dataX_in - repmat(dataX_mean, 1, numFeatures) )./repmat(dataX_std, 1, numFeatures);
            elseif strcmpi(typePreprocessing, 'feature')
                numExamples = size(dataX_in, 1);
                dataX_mean = mean(dataX_in, 1);
                dataX_std = std(dataX_in, 1);
                struct.dataX = ( dataX_in - repmat(dataX_mean, numExamples, 1) )./repmat(dataX_std, numExamples, 1);
                struct.mean = dataX_mean;
                struct.std = dataX_std;
            elseif strcmpi(typePreprocessing, 'minmax')
                dataX_min = min( dataX_in(:) );
                dataX_max = max( dataX_in(:) );
                struct.dataX = ( dataX_in - dataX_min ) / (dataX_max - dataX_min);
                struct.min = dataX_min;
                struct.max = dataX_max;
            elseif strcmpi(typePreprocessing, 'none')
                struct.dataX = dataX_in;
            else
                error('Select a valid method for pre-processing the feature vectors');
            end
        end


        function weights = trainSoftmaxNN(obj,dataX,dataY)

        
            metaParameters = obj.options;
            numNeuronsLayers = obj.numNeuronsLayers;
            
            %fprintf('Training an artificial neural network\n');

            % Initializing the Neural Network Parameters Randomly
            initialTheta = [];
            for i = 2:length(numNeuronsLayers)
                r  = sqrt(6) / sqrt(numNeuronsLayers(i) + numNeuronsLayers(i - 1) + 1);
                W = rand(numNeuronsLayers(i), numNeuronsLayers(i - 1) + 1) * 2 * r - r;
                % mean = 0;
                % sigma = 0.01;
                %     W = normrnd(mean, sigma, numNeuronsLayers(i), numNeuronsLayers(i - 1) + 1);
                initialTheta = [initialTheta; W(:)];
            end

            % Unrolling parameters
            options = optimset('MaxIter', metaParameters.numIterations);
            costFunction = @(t) softmaxNNCostFunction(dataX, dataY,...
                numNeuronsLayers,...
                t,...
                obj.transferFunctions,...
                metaParameters);

            % Now, costFunction is a function that takes in only one argument (the
            % neural network parameters)
            [theta, cost, iterations] = fmincg(costFunction, initialTheta, options);
            
            % Reshaping the weight matrices
            numLayers = length(numNeuronsLayers);
            endPoint = 0;
            for i = 2:numLayers
                numRows = numNeuronsLayers(i);
                numCols = numNeuronsLayers(i - 1) + 1;
                numWeights = numRows*numCols;
                startPoint = endPoint + 1;
                endPoint = endPoint + numWeights;
                weights{i - 1} = reshape(theta(startPoint:endPoint), numRows, numCols);
            end

            % Computing the training error
            [dummyVar, A] = forwardPropagation(dataX, weights, obj.transferFunctions, metaParameters);
            P = A{end};
            [dummyVar, predictedLabels] = max(P, [], 2);
            trainingAccuracy = 100*sum(predictedLabels == dataY)/length(dataY);
            %fprintf('Training Accuracy of the NEURAL NETWORK: %1.2f %%\n\n', trainingAccuracy);
        end
        
        
        
        function [predicted_Y, time, vectorTimePoints] = classifyEMG_SegmentationNN(obj, test_X, nnModel)
       
        % This function applies a hand gesture recognition model based on artificial
        % feed-forward neural networks and automatic feature extraction to a set of
        % EMGs conatined in the set test_X. The actual label of each EMG in test_X
        % is in the set test_Y. The structure nnModel contains the trained neural
        % network              
            
            options = obj.options;  
            
            % Settings for pre-processing
            Fa = options.Fa;
            Fb = options.Fb;
            rectFcn = options.rectFcn;

            % Sliding window settings
            windowLength = options.windowLength;
            strideLength = options.strideLength;

            % Segmentation settings
            segmentation = options.Segmentation;
            FaSegmentation = options.FaSegmentation;
            FbSegmentation = options.FbSegmentation;
            rectFcnSegmentation = options.rectFcnSegmentation;

            % Neural network settings
            typePreprocessingFeatVector = options.typePreprocessingFeatVector;
            centers = nnModel.centers;
            model = nnModel.model;
            transferFunctions = nnModel.transferFunctions;


            % Feature vector pre-processing settings
            try
                meanVal = nnModel.mean;
                stdVal = nnModel.std;
            catch
                meanVal = [];
                stdVal = [];
            end
            try
                minVal = nnModel.min;
                maxVal = nnModel.max;
            catch
                minVal = [];
                maxVal = [];
            end

            numTestingClasses = length(test_X);
            predicted_Y = cell(1, numTestingClasses);
            actual_Y = cell(1, numTestingClasses);
            time = cell(1, numTestingClasses);
            vectorTimePoints = cell(1, numTestingClasses); 
            parfor class_i = 1:numTestingClasses
                test_emg_class_i = test_X{class_i};
                numTestingTrials_class_i = length(test_emg_class_i);
                for trial_j = 1:numTestingTrials_class_i
                   % fprintf('Gesture: %d/%d, Sample: %d/%d\n', ...
                   %     class_i, numTestingClasses, trial_j, numTestingTrials_class_i);
                    test_emg_class_i__trial_j = test_emg_class_i{trial_j};
                    count = 0;
                    emgLength = size(test_emg_class_i__trial_j, 1);
                    if emgLength < windowLength                    
                        missingSamples = ...
                            windowLength - emgLength;                    
                        % --------------------------------------------------------
                        % Solo corregir pequeñas diferencias de adquisición
                        % --------------------------------------------------------                    
                        if missingSamples <= strideLength                    
                            if emgLength == 0                    
                                error( ...
                                    'classifyEMG:EmptySignal', ...
                                    ['Clase %d, prueba %d: ', ...
                                     'la señal EMG está vacía.'], ...
                                    class_i, ...
                                    trial_j);                    
                            end                    
                            % ----------------------------------------------------
                            % Replicar última observación hasta completar
                            % windowLength.
                            %
                            % Ejemplo:
                            % 596 -> agrega 4 observaciones
                            % 598 -> agrega 2 observaciones
                            % ----------------------------------------------------                    
                            padding = repmat( ...
                                test_emg_class_i__trial_j(end,:), ...
                                missingSamples, ...
                                1);                    
                            test_emg_class_i__trial_j = [ ...
                                test_emg_class_i__trial_j
                                padding
                            ];                    
                            % Actualizar longitud
                            emgLength = size( ...
                                test_emg_class_i__trial_j, ...
                                1);                    
                        else                    
                            % ----------------------------------------------------
                            % Si falta demasiado, no ocultar el problema
                            % ----------------------------------------------------                    
                            error( ...
                                'classifyEMG:SignalTooShort', ...
                                ['Clase %d, prueba %d: ', ...
                                 'la señal tiene %d muestras, ', ...
                                 'pero windowLength=%d. ', ...
                                 'Faltan %d muestras, más que strideLength=%d.'], ...
                                class_i, ...
                                trial_j, ...
                                emgLength, ...
                                windowLength, ...
                                missingSamples, ...
                                strideLength);                    
                        end                    
                    end
                    numClassifications = floor((emgLength - windowLength) / strideLength) + 1;
                    predLabelSeq = zeros(1, numClassifications);
                    vecTime = zeros(1, numClassifications);
                    timeSeq = zeros(1, numClassifications);
                    while true
                        startPoint = strideLength*count + 1;
                        %fprintf('inicio: %d\n',startPoint);
                        endPoint = startPoint + windowLength - 1;
                        if endPoint > emgLength
                            break;
                        end
                        % Acquisition of a window observation
                        tStart = tic;
                        window_emg = test_emg_class_i__trial_j(startPoint:endPoint, :);
                        if segmentation
                            % Segmentation of the muscle contraction
                            filtEMG = preProcessEMGSegment(window_emg,...
                                FaSegmentation,...
                                FbSegmentation,...
                                rectFcnSegmentation);
                            [idxStart, idxEnd] = detectMuscleActivity(filtEMG, options);
                        else
                            idxStart = 1;
                            idxEnd = size(window_emg, 1);
                        end
                        t_acq = toc(tStart);
                        % If the muscle contraction is fully contained in the window
                        % observation
                        if idxStart ~= 1 && idxEnd ~= size(window_emg, 1)  && (abs(idxEnd-idxStart) > 90)
                            % Computation of the envelope: rectification and filtering
                            tStart = tic;
                            window_emg = window_emg(idxStart:idxEnd, :);
                            filt_window_emg = preProcessEMGSegment(window_emg, Fa, Fb, rectFcn);
                            t_filt = toc(tStart);
                            % Computing the feature vector using the DTW distance
                            tStart = tic;
                            filt_window_emg_cell = { filt_window_emg };
                            featVector = featureExtraction(filt_window_emg_cell, centers, options);
                            % Pre-processing of the feature vector
                            if strcmpi(typePreprocessingFeatVector, 'vector')
                                featVectorP = ( featVector - mean(featVector) ) / std(featVector);
                            elseif strcmpi(typePreprocessingFeatVector, 'feature')
                                featVectorP = ( featVector - meanVal ) ./ stdVal;
                            elseif strcmpi(typePreprocessingFeatVector, 'minmax')
                                featVectorP = ( featVector - minVal ) / ( maxVal - minVal );
                            elseif strcmpi(typePreprocessingFeatVector, 'none')
                                featVectorP = featVector;
                            end
                            t_featureExtraction = toc(tStart);
                            % Classification of the feature vector
                            tStart = tic;
                            [dummyVar, A] = forwardPropagation(featVectorP,...
                                model, transferFunctions, options);
                            probNN = A{end};
                            [probabilityNN, predictedLabelNN] = max(probNN);
                            t_classificationNN = toc(tStart);
                            % Thresholding
                            tStart = tic;
                            if probabilityNN <= 0.5
                                predictedLabelNN = 1;
                            end
                            t_threshNN = toc(tStart);
                        else
                            t_filt = 0;
                            t_featureExtraction = 0;
                            t_classificationNN = 0;
                            t_threshNN = 0;
                            predictedLabelNN = 1;
                        end
                        % Storing the predictions
                        count = count + 1;
                        predLabelSeq(1, count) = predictedLabelNN;                     
                        vecTime(1, count) = startPoint+(windowLength/2)+10;
                        % Adding up the times
                        timeSeq(1, count) = t_acq + t_filt +...
                            t_featureExtraction + ...
                            t_classificationNN + ...
                            t_threshNN;

                    end
                    predicted_Y{class_i}{trial_j} = majority_vote(predLabelSeq,6,6);
                    time{class_i}{trial_j} = timeSeq;
                    vectorTimePoints{class_i}{trial_j} = vecTime;
                end
            end
        end
        
        
     

        
       function [predictedLabels, time] = posProcessLabels(obj, predictedSeq)
        
            % Número de clases
            numClasses = length(predictedSeq);
        
            predictedLabels = [];
        
            % Celda principal para almacenar tiempos por clase
            time = cell(1, numClasses);
        
            % =========================================================
            % RECORRER TODAS LAS CLASES
            % =========================================================
            for class_i = 1:numClasses
        
                % Número de muestras de testing de esta clase
                numTestingSamples_class_i = ...
                    length(predictedSeq{class_i});
        
                % -----------------------------------------------------
                % IMPORTANTE:
                % Crear una celda para cada muestra de esta clase
                % -----------------------------------------------------
                time{class_i} = ...
                    cell(1, numTestingSamples_class_i);
        
                finalPredictedLabels_class_i = [];
        
                % =====================================================
                % RECORRER LAS MUESTRAS DE ESTA CLASE
                % =====================================================
                for sample_j = 1:numTestingSamples_class_i
        
                    predictions = ...
                        predictedSeq{class_i}{sample_j};
        
                    % -------------------------------------------------
                    % Verificar que existan predicciones
                    % -------------------------------------------------
                    if isempty(predictions)
        
                        warning( ...
                            'Clase %d, muestra %d no contiene predicciones.', ...
                            class_i, ...
                            sample_j);
        
                        continue;
        
                    end
        
                    % La primera clasificación siempre corresponde
                    % a la clase relax
                    predictions(:, 1) = 1;
        
                    % Copia para post-procesamiento
                    postProcessedLabels = predictions;
        
                    % Número de puntos/predicciones temporales
                    numLabels = size(predictions, 2);
        
                    % Número de clasificadores
                    numClassifiers = size(predictions, 1);
        
                    % -------------------------------------------------
                    % Inicializar matriz de tiempos
                    % -------------------------------------------------
                    time{class_i}{sample_j} = ...
                        zeros(numClassifiers, numLabels);
        
                    % =================================================
                    % POST-PROCESAMIENTO
                    % =================================================
                    for label_i = 2:numLabels
        
                        tStart = tic;
        
                        % Comprobar si la predicción actual es igual
                        % a la inmediatamente anterior
                        cond = ...
                            predictions(:, label_i) == ...
                            predictions(:, label_i - 1);
        
                        % Si son iguales, devolver relax (clase 1).
                        % Si son diferentes, mantener la predicción.
                        postProcessedLabels(:, label_i) = ...
                            1 .* cond + ...
                            predictions(:, label_i) .* (1 - cond);
        
                        elapsedTime = toc(tStart);
        
                        time{class_i}{sample_j}(:, label_i) = ...
                            elapsedTime / max(1, numClassifiers);
        
                    end
        
                    % -------------------------------------------------
                    % Tiempo de la primera predicción
                    % -------------------------------------------------
                    if numLabels >= 2
        
                        time{class_i}{sample_j}(:, 1) = ...
                            time{class_i}{sample_j}(:, 2);
        
                    else
        
                        % Si solamente existe una predicción,
                        % no existe columna 2.
                        time{class_i}{sample_j}(:, 1) = 0;
        
                    end
        
                    % =================================================
                    % OBTENER ETIQUETA FINAL
                    % =================================================
                    finalLabel = ...
                        zeros(numClassifiers, 1);
        
                    for classifier_i = 1:numClassifiers
        
                        uniqueLabels = ...
                            unique( ...
                                postProcessedLabels(classifier_i, :) ...
                            );
        
                        % Eliminar la clase relax
                        uniqueLabelsWithoutRest = ...
                            uniqueLabels(uniqueLabels ~= 1);
        
                        if isempty(uniqueLabelsWithoutRest)
        
                            % Solamente se detectó relax
                            finalLabel(classifier_i) = 1;
        
                        elseif length(uniqueLabelsWithoutRest) > 1
        
                            % Existe más de una clase diferente
                            % después del post-procesamiento.
                            % Se conserva el comportamiento original:
                            % tomar la primera.
                            finalLabel(classifier_i) = ...
                                uniqueLabelsWithoutRest(1);
        
                        else
        
                            % Una única clase distinta de relax
                            finalLabel(classifier_i) = ...
                                uniqueLabelsWithoutRest;
        
                        end
        
                    end
        
                    % -------------------------------------------------
                    % Guardar resultado de esta muestra
                    % -------------------------------------------------
                    finalPredictedLabels_class_i = ...
                        [finalPredictedLabels_class_i, finalLabel];
        
                end
        
                % =====================================================
                % CONCATENAR RESULTADOS DE LA CLASE
                % =====================================================
                predictedLabels = ...
                    [predictedLabels, finalPredictedLabels_class_i];
        
            end
        
        end

        function totalTime = computeTime(obj, timeClassification, timePosprocessing) %%%cambio carlos
            numClasses = numel(timeClassification);
            totalTime = cell(1, numClasses);
            for class_i = 1:numClasses        
                numTrialsClassification = ...
                    numel(timeClassification{class_i});        
                numTrialsPosprocessing = ...
                    numel(timePosprocessing{class_i});        
                % -----------------------------------------------------
                % Verificar cantidad de trials
                % -----------------------------------------------------
                if numTrialsClassification ~= numTrialsPosprocessing
        
                    error( ...
                        'computeTime:DifferentNumberOfTrials', ...
                        ['Clase %d: clasificación tiene %d trials ', ...
                         'y postprocesamiento tiene %d trials.'], ...
                        class_i, ...
                        numTrialsClassification, ...
                        numTrialsPosprocessing);        
                end
        
                numTrials = numTrialsClassification;        
                totalTime{class_i} = cell(1, numTrials);
        
                for trial_j = 1:numTrials        
                    time_classification = ...
                        timeClassification{class_i}{trial_j};        
                    time_posprocessing = ...
                        timePosprocessing{class_i}{trial_j};
                    % =================================================
                    % CASO 1:
                    % Ambos están vacíos
                    % =================================================
                    if isempty(time_classification) && ...
                            isempty(time_posprocessing)
        
                        % No hubo clasificación para esta prueba.
                        % Se conserva como vacío.
                        totalTime{class_i}{trial_j} = [];        
                        continue;        
                    end

                    % =================================================
                    % CASO 2:
                    % Solo uno está vacío
                    % =================================================
                    if isempty(time_classification) ~= ...
                            isempty(time_posprocessing)        
                        error( ...
                            'computeTime:OneTimeIsEmpty', ...
                            ['Clase %d, prueba %d: ', ...
                             'solo uno de los vectores de tiempo está vacío. ', ...
                             'Classification=%s, Posprocessing=%s'], ...
                            class_i, ...
                            trial_j, ...
                            mat2str(size(time_classification)), ...
                            mat2str(size(time_posprocessing)));        
                    end

                    % =================================================
                    % CASO 3:
                    % Ambos contienen tiempos
                    % =================================================        
                    % Convertir ambos a vector fila
                    time_classification = ...
                        time_classification(:).';        
                    time_posprocessing = ...
                        time_posprocessing(:).';
                    % Verificar cantidad de elementos
                    if numel(time_classification) ~= ...
                            numel(time_posprocessing)        
                        error( ...
                            'computeTime:DifferentTimeLengths', ...
                            ['Clase %d, prueba %d: ', ...
                             'clasificación tiene %d tiempos ', ...
                             'y postprocesamiento tiene %d tiempos.'], ...
                            class_i, ...
                            trial_j, ...
                            numel(time_classification), ...
                            numel(time_posprocessing));
                    end
                    % =================================================
                    % SUMAR TIEMPOS
                    % =================================================
                    totalTime{class_i}{trial_j} = ...
                        time_classification + ...
                        time_posprocessing;
                end
            end
        end      
        
        function response = recognitionResults( ...
                obj, ...
                predictedLabels, ...
                predictedSeq, ...
                timeClassif, ...
                vectorTime, ...
                typeUser)
        
            res.class = predictedLabels;
            res.vectorOfLabels = predictedSeq;
            res.vectorOfProcessingTime = timeClassif;
            res.vectorOfTimePoints = vectorTime;
        
            gestures = obj.gesture;
        
            numClasses = length(gestures);
        
            cont = 0;
        
            for i_class = 1:numClasses
        
                % Número real de muestras de esta clase
                numSamplesClass = ...
                    length(res.vectorOfLabels{1,i_class});
        
                for i_sample = 1:numSamplesClass
        
                    cont = cont + 1;
        
                    sample = sprintf( ...
                        'idx_%d', ...
                        cont);
        
                    % -------------------------------------------------
                    % Clase final predicha
                    % -------------------------------------------------
        
                    response.class.(sample) = ...
                        categorical( ...
                            string( ...
                                code2gesture( ...
                                    res.class(cont) ...
                                ) ...
                            ) ...
                        );
        
                    % -------------------------------------------------
                    % Secuencia de predicciones
                    % -------------------------------------------------
        
                    tempo = ...
                        res.vectorOfLabels{1,i_class}{1,i_sample};
        
                    % Por defecto: relax
                    StrOut = ...
                        repmat({'relax'}, size(tempo));
        
                    % Convertir cada código numérico en nombre
                    for idxTempo = 1:numel(tempo)
        
                        currentCode = tempo(idxTempo);
        
                        if currentCode >= 1 && ...
                                currentCode <= numClasses
        
                            StrOut{idxTempo} = ...
                                code2gesture(currentCode);
        
                        end
        
                    end
        
                    response.vectorOfLabels.(sample) = ...
                        categorical(StrOut);
        
                    % -------------------------------------------------
                    % Tiempo
                    % -------------------------------------------------
        
                    response.vectorOfTimePoints.(sample) = ...
                        res.vectorOfTimePoints{1,i_class}{1,i_sample};
        
                    response.vectorOfProcessingTime.(sample) = ...
                        res.vectorOfProcessingTime{1,i_class}{1,i_sample};
        
                end
        
            end
        
        end
              
        function generateResultsJSON(obj,dataset)
            txt = jsonencode(dataset);
            fid = fopen('responses.json', 'wt');
            fprintf(fid,txt);
            fclose(fid);
     
        end

    end
end





