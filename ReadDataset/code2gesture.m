function gesture = code2gesture(code)

    switch code

        case 1
            gesture = 'relax';

        case 2
            gesture = 'waveIn';

        case 3
            gesture = 'waveOut';

        case 4
            gesture = 'fist';

        case 5
            gesture = 'open';

        case 6
            gesture = 'pinch';

        case 7
            gesture = 'up';

        case 8
            gesture = 'down';

        case 9
            gesture = 'left';

        case 10
            gesture = 'right';

        case 11
            gesture = 'forward';

        case 12
            gesture = 'backward';

        otherwise
            error( ...
                'code2gesture:UnknownCode', ...
                'Código de gesto no reconocido: %d', ...
                code);
    end

end