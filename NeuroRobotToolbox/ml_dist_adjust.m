
get_dists

medium_dists = dists(medium_inds);

far_inds = medium_dists ~= 0;
close_inds = medium_dists == 0;

xxdata = xdata;
xxdata(far_inds, close_inds) = 0;
xxdata(close_inds, far_inds) = 0;

imagesc(xxdata)

xdata = xxdata;