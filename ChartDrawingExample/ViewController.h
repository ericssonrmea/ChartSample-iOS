//
//  ViewController.h
//  ChartDrawingExample
//
//  Created by Onur A on 07/08/14.
//  Copyright (c) 2014 dev.onur. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "CorePlot-CocoaTouch.h"


@interface ViewController : UIViewController <CPTPlotDataSource>
{
   
}

@property(nonatomic, strong) CPTGraphHostingView *hostView;
@property(nonatomic, strong) CPTTheme *selectedTheme;

-(void) initPlot;
-(void) configureHost;
-(void) configureGraph;
-(void) configurePlots;
-(void) configureAxes;

@end
