function [P_Fs, P_Ds] = get_roc_curve(threshs, H0, H1)
    % GET_ROC_CURVE     Computes the receiver operating characteristic
    %                   curve for a detector defined by its hypothesis PDFs.
    %
    %   threshs:    thresholds at which to evaluate the probabilities
    %   H0:         PDF (likelihood) of "negative" hypothesis: no detection
    %   H1:         PDF (likelihood) of "positive" hypothesis: detection
    %
    %   P_Fs:       False alarm probability per threshold
    %   P_Ds:       Detection probability per threshold

    P_Fs = zeros(size(threshs));
    P_Ds = zeros(size(threshs));
    
    for i=1:length(threshs)
        thresh = threshs(i);
        P01_ = double(int(H0, thresh, inf));
        P11_ = double(int(H1, thresh, inf));
    
        P_Fs(i) = P01_;
        P_Ds(i) = P11_;
    end
end