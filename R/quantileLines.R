#' @title Add quantile lines to a paired scatterplot
#' 
#' @description \code{quantileLines} Adds line segments at the requested quantiles of the x and y variables.
#' This is a useful addition to a paired scatterplot, to illustrate how observations are linked between conditions.
#' The quantile lines are set as the lowest layer, so they won't obscure the original paired scatterplot.
#' Adapted from the \href{https://github.com/GRousselet/rogme/blob/master/R/plot_utils.R}{plot_quartile_bars} function in the rogme package.
#' 
#' @param p the ggplot object to which the quantile lines should be added.
#' @param probs numeric vector of probabilities with values in [0,1].
#' @param colour_m character indicating the colour of the middle line.
#' @param colour character indicating the colour of the other lines.
#' @param size_m numeric indicating the thickness of the middle line.
#' @param size numeric indicating the thickness of the other lines.
#' @param linetype_m character indicating the linetype of the middle line.
#' @param linetype character indicating the linetype of the other lines.
#' 
#' @details In order for these quantile lines to make sense, the axes of the plot should be identically scaled.
#' 
#' @author Frank H. Hezemans, \email{Frank.Hezemans@@mrc-cbu.cam.ac.uk}
#' @seealso \code{\link[stats]{quantile}}, \code{\link[ggplot2]{geom_segment}}
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
#' # Add lines at the first quartile, median, and third quartile
#' paired_scatter <- quantileLines(paired_scatter, probs = c(0.25, 0.5, 0.75),
#'                                 colour_m = "black", colour = "grey",
#'                                 size_m = 0.5, size = 0.25,
#'                                 linetype_m = "longdash", linetype = "dashed")          
#' 
#' @export
#' 
quantileLines <- function(p, probs = c(0.25, 0.5, 0.75),
                          colour_m = "darkgrey", colour = "grey",
                          size_m = 0.5, size = 0.25,
                          linetype_m = "dashed", linetype = "dashed"){
  
  # Check if the axes are identically scaled
  xrange <- ggplot2::ggplot_build(p)$layout$panel_ranges[[1]]$x.range
  yrange <- ggplot2::ggplot_build(p)$layout$panel_ranges[[1]]$y.range
  if (!all(xrange == yrange)){
    warning("The axes are not identically scaled, so the quantile lines will probably be misleading!")
  }
  
  # Get the raw data used in the plot
  data <- ggplot2::ggplot_build(p)$data
  if (length(data) > 1){
    # The object with the real data probably has the most rows; determine which one that is
    index <- which.max(sapply(data, nrow))
    data <- data[[index]]
  }
  
  # Calculate the requested quantiles for x and y variables
  q_x <- quantile(data$x, probs = probs, na.rm = TRUE, names = FALSE)
  q_y <- quantile(data$y, probs = probs, na.rm = TRUE, names = FALSE)
  
  # Determine which line(s) should be considered the middle
  value_m <- (length(probs)+1)/2
  index_m <- unique(c(floor(value_m), ceiling(value_m)))
  
  # Define formatting
  colours <- rep(colour, times = length(probs))
  colours[index_m] <- colour_m
  sizes <- rep(size, times = length(probs))
  sizes[index_m] <- size_m
  linetypes <- rep(linetype, times = length(probs))
  linetypes[index_m] <- linetype_m
  
  # Initialise two lists that will hold the horizontal and vertical line segments respectively
  hor_segments <- vector("list", length = length(probs))
  ver_segments <- vector("list", length = length(probs))
  
  # Iteratively build the quantile line segments
  for (i in 1:length(probs)){
    
    hor_segments[[i]] <- ggplot2::geom_segment(
      x = -Inf, y = q_y[i],
      xend = q_x[i], yend = q_y[i],
      linetype = linetypes[i],
      colour = colours[i],
      size = sizes[i])
    
    ver_segments[[i]] <- ggplot2::geom_segment(
      x = q_x[i], y = -Inf,
      xend = q_x[i], yend = q_y[i],
      linetype = linetypes[i],
      colour = colours[i],
      size = sizes[i])
    
  }
  
  # Initialise a list that will hold all the line segments
  line_list <- vector("list", length = length(probs) * 2)
  # Fill this list with the segments, alternating horizontal and vertical
  line_list[c(TRUE, FALSE)] <- hor_segments
  line_list[c(FALSE, TRUE)] <- ver_segments
  
  
  # Build the final plot, placing the line segments below pre-existing layers
  p$layers <- c(line_list, p$layers)
  return(p)
}