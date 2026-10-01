function code = gesture2code(gesture)

    gesture = lower(strtrim(char(string(gesture))));

    switch gesture

        case {'relax', 'nogesture'}
            code = 1;

        case 'wavein'
            code = 2;

        case 'waveout'
            code = 3;

        case 'fist'
            code = 4;

        case 'open'
            code = 5;

        case 'pinch'
            code = 6;

        case 'up'
            code = 7;

        case 'down'
            code = 8;

        case 'left'
            code = 9;

        case 'right'
            code = 10;

        case 'forward'
            code = 11;

        case 'backward'
            code = 12;

        otherwise
            error( ...
                'gesture2code:UnknownGesture', ...
                'Gesto no reconocido: "%s"', ...
                gesture);
    end

end