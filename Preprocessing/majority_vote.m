function class_maj = majority_vote(class, before, after)

    % Vector para almacenar la clase mayoritaria
    class_maj = zeros(size(class));

    % Número máximo de clases presentes
    numClasses = max(class);

    for i = 1:length(class)

        % -----------------------------------------------------
        % Crear ventana alrededor de la predicción actual
        % -----------------------------------------------------
        startIdx = max(1, i - before);
        endIdx   = min(length(class), i + after);

        window = class(startIdx:endIdx);

        % -----------------------------------------------------
        % Contar votos de cada clase
        % -----------------------------------------------------
        votes = zeros(1, numClasses);

        for j = 1:numClasses

            votes(j) = sum(window == j);

        end

        % -----------------------------------------------------
        % Seleccionar la clase con más votos
        %
        % Si hay empate, se selecciona el código menor.
        % -----------------------------------------------------
        [~, class_maj(i)] = max(votes);

    end

end