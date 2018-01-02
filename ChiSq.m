function D2 = ChiSq(XI, XJ)
D2 = 0.5*sum((XI-XJ).^2 ./ (XI+XJ+eps), 2);

end

