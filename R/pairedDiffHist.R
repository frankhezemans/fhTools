#' @title Add histogram of paired difference on the identity line
#' 
#' @description \code{pairedDiffHist} Adds a histogram on the identity line which illustrates the distribution of the difference between two conditions.
#' This is a useful addition to a paired scatterplot, to illustrate how the conditions differ within the sample.
#' Each histogram bin is manually added to the plot with \code{geom_polygon}.
#' 
#' @param p the ggplot object to which the histogram should be added.
#' @param origin number indicating the center of the histogram on the plot.
#' @param maxheight number indicating the desired height of the tallest bin.
#' @param colour,fill,size aesthetics for the histogram bins.
#' @param bins,binwidth the number of bins / the width of the bins.
#' @param meanline logical. Should a line segment at the mean of the histogram be added?
#' @param meanline_pos number indicating by how much the line should extend the dimensions of the biggest histogram bin.
#' @param meanline_colour,meanline_size,meanline_type aesthetics of the mean line.
#' @param sigstars number indicating the amount of stars to be added at the mean of the distribution, to indicate significance level of difference. Default is NULL.
#' @param sigstars_pos number indicating by how much the significance stars should be shifted up from the top of the mean line
#' @param sigstars_colour,sigstars_size aesthetics of the significance stars.
#' 
#' @details In order for the histogram to make sense, the axes of the plot should be identically scaled. Ideally the aspect ratio is set to one, using \code{theme(aspect.ratio = 1)}.
#' 
#' @author Frank H. Hezemans, \email{Frank.Hezemans@@mrc-cbu.cam.ac.uk}
#' @seealso \code{\link[ggplot2]{geom_histogram}}, \code{\link[ggplot2]{geom_polygon}}, \code{\link[ggplot2]{annotate}}
#' 
#' @examples
#' library(ggplot2)
#' library(UsingR) # Package contains dataset
#' 
#' # Get data
#' data <- crime
#' 
#' # Create paired scatterplot
#' paired_scatter <- ggplot(data = data, aes(x = y1983, y = y1993)) +
#'     geom_abline(slope = 1, intercept = 0) +
#'     geom_point(shape = 21, fill = "grey") +
#'     xlim(0, 1500) + ylim(0, 1500) +
#'     labs(title = "Violent crime in 50 U.S. states in 1983 and 1993",
#'          subtitle = "Rates per 100,000 population",
#'          x = "Violent crime rate in 1983",
#'          y = "Violent crime rate in 1993") +
#'     theme_minimal() +
#'     theme(aspect.ratio = 1)
#'
#' # Add histogram of paired differences
#' paired_scatter <- pairedDiffHist(paired_scatter, origin = 1250, maxheight = 100,
#'                                  colour = "black", fill = "grey", size = 1,
#'                                  bins = 6, meanline = TRUE, sigstars = 3,
#'                                  sigstars_pos = 25)
#' 
#' @export
#' 
pairedDiffHist <- function(p, origin, maxheight,
                         colour = "black", fill = "grey", size = 1,
                         bins = NULL, binwidth = NULL,
                         meanline = FALSE, meanline_pos = 0,
                         meanline_colour = "black",
                         meanline_size = 1, meanline_type = "solid",
                         sigstars = NULL, sigstars_pos = 0,
                         sigstars_colour = "black", sigstars_size = 1){
  
  # Check if the axes are identically scaled
  xrange <- ggplot2::ggplot_build(p)$layout$panel_ranges[[1]]$x.range
  yrange <- ggplot2::ggplot_build(p)$layout$panel_ranges[[1]]$y.range
  if (!all(xrange == yrange)){
    stop("The axes are not identically scaled!")
  }
  
  # Get the raw data used in the plot
  data <- ggplot2::ggplot_build(p)$data
  if (length(data) > 1){
    # The real data is probably in geom_point(), which can be uniquely identified by the "shape" aesthetic
    for (i in 1:length(data)){
      if ("shape" %in% names(data[[i]])){
        data <- data[[i]]
      }
    }
  }
  
  # Calculate the difference between x and y
  data$diff_score <- data$x - data$y
  
  # Use this difference score to build a histogram
  histogram <- ggplot(data = data, aes(x = diff_score)) +
    if ((is.null(bins)) & (is.null(binwidth))){
      geom_histogram()
    } else if (!is.null(binwidth)){
      geom_histogram(binwidth = binwidth)
    } else if (!is.null(bins)){
      geom_histogram(bins = bins)
    }
  
  # Extract the coordinates of the histogram bins, and calculate the relative height of each bin
  hist_data <- ggplot_build(histogram)$data[[1]]
  hist_data$yrelative <- hist_data$ymax / max(hist_data$ymax)
  
  # In order to manually reconstruct histogram bins, we need to transform four coordinates of each bin to a 45 degree angle.
  # When the difference score is negative (y is greater than x), you can think of a point goes to the left by the difference score from the origin on the identity line.
  # You can think of this imaginary line as the hypothenuse of a right triangle.
  # We know all angles of this triangle (45, 45, 90), and we know the length of one side.
  # When we know the lengths of the other side, we can determine the x- and y-coordinate of a histogram bin.
  
  angle <- cos(45 * (pi / 180)) # since it's 45 degrees, doesn't matter if we use cos or sin
  
  # Initialise a list that will hold the geom_polygon objects
  polygons <- vector("list", length = nrow(hist_data))
  
  
  
  # Now we need to iteratively determine the x and y coordinates of each bin, for a histogram that is angled at 45 degrees
  for (i in 1:nrow(hist_data)){
    
    # Initialise vectors that will hold the x- and y-coordinates in the order bottom-left, bottom-right, top-right, top-left
    x <- vector("numeric", length = 4)
    y <- vector("numeric", length = 4)
    
    # The origin is different for the bottom and top coordinates of the bin
    origins <- c(rep(origin, times = 2),
                 rep((origin + (maxheight * hist_data$yrelative[i])), times = 2))
    
    hypothenuse <- c(hist_data$xmin[i], hist_data$xmax[i],
                     hist_data$xmax[i], hist_data$xmin[i])
    
    # Iteratively determine each of the 4 x- and y-coordinates
    for (j in 1:4){
      
      legs <- hypothenuse[j] * angle
      
      # Solution from here: https://math.stackexchange.com/a/1989113
      y[j] <- (hypothenuse[j]^2) / (2 * hypothenuse[j])
      x[j] <- sqrt(legs^2 - (y[j])^2)
      
      y[j] <- origins[j] - y[j]
      x[j] <- origins[j] - (sign(y[j] - origins[j]) * x[j])
    }

    # Use these coordinates to create a geom_polygon, and add this to the list
    polygons[[i]] <- ggplot2::geom_polygon(data = data.frame(x = x, y = y),
                                           mapping = aes(x = x, y = y),
                                           colour = colour, fill = fill, size = size)
    
  }
  
  # Add these polygons to the existing figure
  p$layers <- c(p$layers, polygons)
  
  # Check if we should add further details
  if (any(!is.null(sigstars), meanline == TRUE)){
    
    # For these details, we need the x- and y-coordinates of the mean on the histogram
    meanDiff <- mean(data$diff_score, na.rm = TRUE)
    
    x_mean <- vector("numeric", length = 2)
    y_mean <- vector("numeric", length = 2)
    
    origins <- c((origin - meanline_pos), (origin + maxheight + meanline_pos))
    
    for (j in 1:2){
      
      hypothenuse <- meanDiff
      legs <- hypothenuse * angle
      
      y_mean[j] <- (hypothenuse^2) / (2 * hypothenuse)
      x_mean[j] <- sqrt(legs^2 - (y_mean[j])^2)
      
      y_mean[j] <- origins[j] - y_mean[j]
      x_mean[j] <- origins[j] - (sign(y_mean[j]) * x_mean[j])
      
    }
    
    if (meanline == TRUE){
      
      p <- p + ggplot2::annotate("segment", x = x_mean[1], y = y_mean[1],
                                 xend = x_mean[2], yend = y_mean[2],
                                 colour = meanline_colour, size = meanline_size,
                                 linetype = meanline_type)
      
    }
    
    if (!is.null(sigstars)){
      
      p <- p + ggplot2::annotate("text", x = x_mean[2] + sigstars_pos,
                                 y = y_mean[2] + sigstars_pos,
                                 label = strrep("*", times = sigstars),
                                 angle = -45, colour = sigstars_colour,
                                 size = sigstars_size)
    }
    
  }
  
  return(p)
  
}