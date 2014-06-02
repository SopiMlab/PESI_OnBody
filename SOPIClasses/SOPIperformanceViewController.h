/*
 *
 * Created by: Koray Tahiroğlu, Miguel Valero Espada, Nuno Correia, James Nesfield;
 * Academy of Finland (project 137646) The Notion of Participative and Enacting Sonic Interaction - PESI
 * SOPI research group, Aalto University, School of Arts, Design and Architecture
 *
 * Copyright (c) 2013 Aalto University. All rights reserved. <koray.tahiroglu@aalto.fi>
 *
 * BSD Simplified License.
 * For information on usage and redistribution, and for a DISCLAIMER OF ALL
 * WARRANTIES, see the file, "LICENSE.txt," in this distribution.
 *
 * See https://github.com/SopiMlab/ for documentation
 *
 */


//
//  SOPIperformanceViewController.h
//  SOPImobile
//


//This file uses code from CocoaOSC:
//https://github.com/danieldickison/CocoaOSC/
//More info about CocoaOSC in the README.txt file, inside the CocoaOSC folder
//

#import <UIKit/UIKit.h>
#import "SOPIsettingViewController.h"
#import "OSCConnectionDelegate.h"
#import <CoreMotion/CoreMotion.h>
#import <Foundation/Foundation.h>

@interface SOPIperformanceViewController : UIViewController<PdListener,UIAccelerometerDelegate>{
    PdDispatcher* dispatcher;
    void *patch;
    NSInteger numberOfCurrentTouches;
    NSInteger presetNum;
    NSTimer *timerPing;
    NSTimer *timerMain;
    NSString *mainHost;
    NSString *mainPort;
    float touchX;
    float touchY;
    Boolean tuningOn;
    Boolean touchOn;
    OSCConnection *connection;
    CGPoint lastTune1, lastTune2, lastTune3, lastTune4;
    NSArray *myTunes;
    float myIP;
    NSString* plistPath;
    NSString* path;
    NSMutableDictionary *dict;
    Boolean touchingTune;
    Boolean touchesMoving;
    CGPoint myTune1pl, myTune2pl, myTune3pl, myTune4pl;
    
}


@property (weak, nonatomic) IBOutlet UIButton *settingsButton;
@property (weak, nonatomic) IBOutlet UIButton *tuningButton;
@property (weak, nonatomic) IBOutlet UISegmentedControl *presetSegment;
@property (weak, nonatomic) IBOutlet UIButton *presetButton;
@property (nonatomic, retain) IBOutlet UILabel *tuningLabel;
@property (nonatomic, retain) IBOutlet UILabel *presetLabel;
@property (nonatomic,strong) PdDispatcher *dispatcher;
@property (nonatomic, weak) UIAccelerometer *accelerometer;

- (IBAction)presetButton:(id)sender;
- (IBAction)presetSegment:(id)sender;
- (IBAction)goToSettingsButton:(id)sender;
- (IBAction)goToTuningButton:(id)sender;

@end
