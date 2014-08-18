//
//  ViewController.m
//  ChartDrawingExample
//
//  Created by Onur A on 07/08/14.
//  Copyright (c) 2014 dev.onur. All rights reserved.
//

#import "ViewController.h"



@interface ViewController ()
{
    NSData *nsData;
    int currentIndex;
    NSArray *urls;
    NSArray *cities;
    NSMutableArray *values;
}
@end

#define CITY_COUNT 5
#define IPHONE [[UIDevice currentDevice]userInterfaceIdiom]==UIUserInterfaceIdiomPhone

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    
    nsData=[[NSData alloc] init];
    
    currentIndex=0;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"cities" ofType:@"plist"];
    
    NSDictionary *dict=[NSMutableDictionary dictionaryWithContentsOfFile:path];
    
    urls=[dict allValues];
    cities=[dict allKeys];
    
    values=[NSMutableArray arrayWithCapacity:CITY_COUNT];
    
   
    [self sendRequestwithURL:[urls objectAtIndex:currentIndex++]];
}

-(void)sendRequestwithURL:(NSString*)url
{
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url]
                                              cachePolicy:NSURLRequestUseProtocolCachePolicy
                                          timeoutInterval:60.0];
    
    [NSURLConnection connectionWithRequest:theRequest delegate:self];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    nsData=data;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    NSError *localError = nil;
    NSDictionary *parsedObject = [NSJSONSerialization JSONObjectWithData:nsData options:0 error:&localError];
  
    NSDictionary *results = parsedObject[@"main"];
    NSNumber *value=[NSNumber numberWithInt:[results[@"temp"] integerValue]];
    NSLog(@"Value %d: %@",currentIndex,value);
    [values addObject:value];
    
    if (currentIndex<[urls count])
    {
        [self sendRequestwithURL:[urls objectAtIndex:currentIndex++]];
    }
    else
    {
        [self initPlot];
    }
}

-(void)initPlot
{
    [self configureHost];
    [self configureGraph];
    [self configurePlots];
    [self configureAxes];
}

-(void)configureHost
{
    CGRect parentRect = self.view.bounds;
    CGSize toolbarSize = self.navigationController.toolbar.bounds.size;
    parentRect = CGRectMake(parentRect.origin.x,
                            (parentRect.origin.y + toolbarSize.height),
                            parentRect.size.width,
                            (parentRect.size.height - toolbarSize.height));
    
    self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:parentRect];
    self.hostView.allowPinchScaling = NO;
   
    if(IPHONE)
    {
        self.hostView.layer.transform = CATransform3DConcat(self.hostView.layer.transform, CATransform3DMakeRotation(M_PI,1.0,0.0,0.0));
    }
    
    [self.view addSubview:self.hostView];
}

-(void)configureGraph
{
    // 1 - Create the graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    [graph applyTheme:[CPTTheme themeNamed:kCPTSlateTheme]];
    self.hostView.hostedGraph = graph;
    
    // 2 - Set graph title
    NSString *title = @"Weather Forecast";
    graph.title = title;
    
    // 3 - Create and set text style
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor whiteColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 16.0f;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, -10.0f);
    
    // 4 - Set padding for plot area
    [graph.plotAreaFrame setPaddingLeft:0.0f];
    [graph.plotAreaFrame setPaddingBottom:0.0f];
    [graph.plotAreaFrame setPaddingRight:0.0f];
    [graph.plotAreaFrame setPaddingTop:0.0f];
   
    // 5 - Enable user interactions for plot space
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
}

-(void)configurePlots
{
    CPTGraph *graph=self.hostView.hostedGraph;
    CPTXYPlotSpace *plotSpace=(CPTXYPlotSpace *) graph.defaultPlotSpace;
 
    CPTScatterPlot *plot = [[CPTScatterPlot alloc] init];
    plot.dataSource = self;
    plot.identifier = @"WEATHER";
    CPTColor *plotColor = [CPTColor blueColor];
    [graph addPlot:plot toPlotSpace:plotSpace];
    
    [plotSpace scaleToFitPlots:[NSArray arrayWithObjects:plot,nil]];
    
    CPTMutablePlotRange *xRange=[plotSpace.xRange mutableCopy];
    [xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
    
    plotSpace.xRange=xRange;
    
    CPTMutablePlotRange *yRange=[plotSpace.yRange mutableCopy];
    
    yRange=[[CPTPlotRange plotRangeWithLocation:CPTDecimalFromCGFloat(0.0f) length:CPTDecimalFromCGFloat(30)] mutableCopy];
    [yRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
    
    plotSpace.yRange=yRange;
    
    CPTMutableLineStyle *googLineStyle = [plot.dataLineStyle mutableCopy];
    googLineStyle.lineWidth = 1.5;
    googLineStyle.lineColor = plotColor;
    plot.dataLineStyle = googLineStyle;
    CPTMutableLineStyle *googSymbolLineStyle = [CPTMutableLineStyle lineStyle];
    googSymbolLineStyle.lineColor = plotColor;
    CPTPlotSymbol *googSymbol = [CPTPlotSymbol starPlotSymbol];
    googSymbol.fill = [CPTFill fillWithColor:plotColor];
    googSymbol.lineStyle = googSymbolLineStyle;
    googSymbol.size = CGSizeMake(9.0f, 9.0f);
    plot.plotSymbol = googSymbol;
}


-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot
{
    return [cities count];
}

-(id)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
    
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            if (idx < CITY_COUNT) {
                return [NSNumber numberWithUnsignedInteger:idx];
            }
            break;
            
        case CPTScatterPlotFieldY:
            return [values objectAtIndex:idx];
    }
    return [NSDecimalNumber zero];
    
}

-(void)configureAxes
{
    // 1 - Create styles
    CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
    axisTitleStyle.color = [CPTColor whiteColor];
    axisTitleStyle.fontName = @"Helvetica-Bold";
    axisTitleStyle.fontSize = 14.0f;
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 2.0f;
    axisLineStyle.lineColor = [CPTColor whiteColor];
    CPTMutableTextStyle *axisTextStyle = [[CPTMutableTextStyle alloc] init];
    axisTextStyle.color = [CPTColor whiteColor];
    axisTextStyle.fontName = @"Helvetica-Bold";
    axisTextStyle.fontSize = 10.0f;
    CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor whiteColor];
    tickLineStyle.lineWidth = 2.0f;
    CPTMutableLineStyle *gridLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor blackColor];
    tickLineStyle.lineWidth = 1.0f;
   
    // 2 - Get axis set
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    
    // 3 - Configure x-axis
    CPTAxis *x = axisSet.xAxis;
    x.title = @"Cities";
    x.titleTextStyle = axisTitleStyle;
    x.titleOffset = 20.0f;
    x.axisLineStyle = axisLineStyle;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.labelTextStyle = axisTextStyle;
    x.majorTickLineStyle = axisLineStyle;
    x.majorTickLength = 4.0f;
    x.tickDirection = CPTSignNegative;
   
    NSMutableSet *xLabels = [NSMutableSet setWithCapacity:CITY_COUNT];
    NSMutableSet *xLocations = [NSMutableSet setWithCapacity:CITY_COUNT];
    
    NSInteger i = 0;
    for (NSString *city in cities) {
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:city  textStyle:x.labelTextStyle];
        CGFloat location = i++;
        label.tickLocation = CPTDecimalFromCGFloat(location);
        label.offset = x.majorTickLength;
        if (label) {
            [xLabels addObject:label];
            [xLocations addObject:[NSNumber numberWithFloat:location]];
        }
    }
    x.axisLabels = xLabels;
    x.majorTickLocations = xLocations;
    // 4 - Configure y-axis
    
    CPTAxis *y = axisSet.yAxis;
    y.title = @"Celcius";
    y.titleTextStyle = axisTitleStyle;
    y.titleOffset = -27.0f;
    y.axisLineStyle = axisLineStyle;
    y.majorGridLineStyle = gridLineStyle;
    y.labelingPolicy = CPTAxisLabelingPolicyNone;
    y.labelTextStyle = axisTextStyle;
    y.labelOffset = 10.0f;
    y.majorTickLineStyle = axisLineStyle;
    y.majorTickLength = 4.0f;
    y.minorTickLength = 2.0f;
    y.tickDirection = CPTSignPositive;
    
    
    
    NSInteger majorIncrement = 2;
    NSInteger minorIncrement = 2;
    CGFloat yMax = 30.0f;
    NSMutableSet *yLabels = [NSMutableSet set];
    NSMutableSet *yMajorLocations = [NSMutableSet set];
    NSMutableSet *yMinorLocations = [NSMutableSet set];
    for (NSInteger j = minorIncrement; j <= yMax; j += minorIncrement) {
        NSUInteger mod = j % majorIncrement;
        
        if (mod == 0) {
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%i", j] textStyle:y.labelTextStyle];
            NSDecimal location = CPTDecimalFromInteger((j));
            label.tickLocation = location;
            label.offset = -y.majorTickLength - y.labelOffset;
            if (label) {
                [yLabels addObject:label];
            }
            [yMajorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:(location)]];
        } else {
            [yMinorLocations addObject:[NSDecimalNumber decimalNumberWithDecimal:CPTDecimalFromInteger(j)]];
        }
    }
    y.axisLabels = yLabels;    
    y.majorTickLocations = yMajorLocations;
    y.minorTickLocations = yMinorLocations;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end
