function code = codeSamples(kRep, gestureData)

    rep = sprintf('idx_%d', kRep);

    % Verificar que la muestra exista
    if ~isfield(gestureData, rep)
        error( ...
            'codeSamples:SampleNotFound', ...
            'No existe la muestra %s.', ...
            rep);
    end

    % Verificar que exista gestureName
    if ~isfield(gestureData.(rep), 'gestureName')
        error( ...
            'codeSamples:GestureNameNotFound', ...
            'La muestra %s no contiene gestureName.', ...
            rep);
    end

    % Obtener código según el nombre real del gesto
    code = gesture2code(gestureData.(rep).gestureName);

end