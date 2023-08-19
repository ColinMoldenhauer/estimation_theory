function [P00, P01, P10, P11] = get_detection_probabilities(H0, H1, thresh)
    % GET_DETECTION_PROBABILITIES  Determines the detection probabilites
    %                              from the associated detection PDFs.
    %
    %   P00: Probability of correct negative detection
    %   P01: Probability of wrong positive detection (false alarm P_F)
    %   P10: Probability of wrong negative detection (missed detection P_M)
    %   P11: Probability of correct positive detection (P_D)

    P00 = double(int(H0, x, -inf, thresh));
    P01 = double(int(H0, thresh, inf));
    P10 = double(int(H1, x, -inf, thresh));
    P11 = double(int(H1, thresh, inf));
end