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
//  SOPIperformanceViewController.m
//  SOPImobile
//


#import "SOPIperformanceViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SOPIAppDelegate.h"
#import "AsyncUdpSocket.h"
#import "CocoaOSC.h"

#include <ifaddrs.h>
#include <arpa/inet.h>

#define kTransitionDuration	0.75
#define kUpdateFrequency 100  // Hz
#define kFilteringFactor 0.1
#define kNoReadingValue 999


@interface SOPIperformanceViewController (){
    UIAccelerationValue accelerationX;
    UIAccelerationValue accelerationY;
    UIAccelerationValue accelerationZ;
    double gyroscopeX;
    double gyroscopeY;
    double gyroscopeZ;

}


@property (nonatomic, strong) IBOutlet UIImageView *fingerCircle;
@property (nonatomic, strong) IBOutlet UIImageView *tune1;
@property (nonatomic, strong) IBOutlet UIImageView *tune2;
@property (nonatomic, strong) IBOutlet UIImageView *tune3;
@property (nonatomic, strong) IBOutlet UIImageView *tune4;
@property (nonatomic, strong) IBOutlet UIImageView *pingInSquare;
@property (nonatomic, strong) IBOutlet UIImageView *pingOutSquare;
@end

@implementation SOPIperformanceViewController

CMMotionManager *motionManager;


@synthesize settingsButton;
@synthesize tuningButton;
@synthesize dispatcher;
@synthesize accelerometer;
@synthesize fingerCircle;
@synthesize tune1;
@synthesize tune2;
@synthesize tune3;
@synthesize tune4;
@synthesize pingInSquare;
@synthesize pingOutSquare;
@synthesize presetButton;
@synthesize presetSegment;
@synthesize tuningLabel;
@synthesize presetLabel;

//Pd EXTERNAL OBJECT
//here you can add Pd externals, this is the setup function to register the external. For Pd spesific, remember to add -DPD flag unders Other C Flags in Build Settings, also do not forget to add the source code of the external in the folder under pd-for-ios/libpd/pure-data/extra.

// Apple Store rule - check the licencing info of the externals that you are using in your project--

void fiddle_tilde_setup(); // test external for fiddle~





//PESI_OnBody on SCREEN-------------------------------------------------

- (void)viewDidLoad
{
    //Setup and UI
    [super viewDidLoad];
    [self.view setMultipleTouchEnabled:YES];
    motionManager = [(SOPIAppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    [fingerCircle removeFromSuperview];
    [tuningLabel removeFromSuperview];
    [presetLabel removeFromSuperview];
    
    //Plist
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    path = [documentsDirectory stringByAppendingPathComponent:@"plist.plist"]; NSFileManager *fileManager = [NSFileManager defaultManager];
    
    if (![fileManager fileExistsAtPath: path]){
        plistPath = [[NSBundle mainBundle] pathForResource:@"SOPI" ofType:@"plist"];
        dict = [[NSMutableDictionary alloc] initWithContentsOfFile:plistPath];
    }else{
        dict = [[NSMutableDictionary alloc] initWithContentsOfFile:path];
    }

    //PD
    dispatcher=[[PdDispatcher alloc]init];
    [dispatcher addListener:self forSource:@"vibrate"];
    [PdBase setDelegate:dispatcher];

    //Pd EXTERNAL OBJECT
    fiddle_tilde_setup(); // test external for fiddle~
 
    
    
    patch=[PdBase openFile:@"_PESI.pd" path:[[NSBundle mainBundle]resourcePath]];
    if(!patch){
        NSLog(@"couldn't open patch");
    }
    [PdBase sendFloat:0.0 toReceiver:@"screenIsBeingTouched"];
    [PdBase sendFloat:[[[NSUserDefaults standardUserDefaults]valueForKey:@"colourDefault"]integerValue] toReceiver:@"instID"];
    
    
    
    //Background
    switch ([[[NSUserDefaults standardUserDefaults]valueForKey:@"colourDefault"]integerValue]) {
        case 1:
            [self.view setBackgroundColor:[UIColor colorWithRed:0 green:139/255.f blue:0 alpha:1]];
            break;
        case 2:
            [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:139/255.f alpha:1]];
            break;
        default:
            [self.view setBackgroundColor:[UIColor colorWithRed:139/255.f green:0 blue:0 alpha:1]];
            break;
    }
    
    //Tuning
    myTunes = [NSArray arrayWithObjects: tune1, tune2, tune3, tune4, nil];
    for(int i=0; i<4; i++){
        ((UIImageView *) [myTunes objectAtIndex: i]).alpha=0.1;
    }
    presetButton.hidden=YES;
    presetSegment.hidden=YES;
    presetNum=presetSegment.selectedSegmentIndex;
    [self doTuning];
    
    //OSC
    connection = [[OSCConnection alloc] init];
    connection.delegate = self;
    connection.continuouslyReceivePackets = YES;
    NSError *error;
    if (![connection bindToAddress:nil port:11000 error:&error])
    {
        NSLog(@"Could not bind UDP connection: %@", error);
    }
 
    [connection receivePacket];
    //NOTE: ADD HOST IP AND PORT HERE:
    mainHost = @"169.254.0.1";
    mainPort = @"12000";
    timerPing = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(loopPing) userInfo:nil repeats:YES];
    //NOTE: CHANGE TIMER INTERVAL, IN MILLISECONDS, HERE:
    timerMain = [NSTimer scheduledTimerWithTimeInterval:0.10 target:self selector:@selector(loopMain) userInfo:nil repeats:YES];
    touchX = 0;
    touchY = 0;
    tuningOn = 0;
    touchesMoving = 0;
    pingOutSquare.alpha=0.5;
    pingInSquare.alpha=0.5;
    [self hideSquareIn];
    
    //IP Address
    NSString *myWholeIP=[self getIPAddress];
    NSRange myIPRange=[myWholeIP rangeOfString:@"." options:NSBackwardsSearch];
    if(myIPRange.length==1){
        //NOTE: "myIP" IS THE LAST DIGIT IN THE IP ADDRESS; IT IDENTIFIES DEVICE IN OSC:
        myIP = [[myWholeIP substringFromIndex:myIPRange.location+1] floatValue];
    }else{
        myIP = -1;
    }
    [[NSUserDefaults standardUserDefaults] setValue:myWholeIP forKey:@"ipDefault"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [super viewDidLoad];
}

- (void)viewDidUnload{
    NSLog(@"unloading performance");
    [self setSettingsButton:nil];
    [self setTuningButton:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    [PdBase closeFile:patch];
    [PdBase setDelegate:nil];
}

-(void)viewDidAppear:(BOOL)animated{
    if([[NSUserDefaults standardUserDefaults]boolForKey:@"accelerometerDefault"])
        [self startAccelerometerUpdates];
    if([[NSUserDefaults standardUserDefaults]boolForKey:@"gyroscopeDefault"])    
        [self startGyroscopeUpdates];
    
    [self doTuning];
    switch ([[[NSUserDefaults standardUserDefaults]valueForKey:@"colourDefault"]integerValue]) {
        case 1:
            [self.view setBackgroundColor:[UIColor colorWithRed:0 green:139/255.f blue:0 alpha:1]];
            break;
        case 2:
            [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:139/255.f alpha:1]];
            break;
        default:
            [self.view setBackgroundColor:[UIColor colorWithRed:139/255.f green:0 blue:0 alpha:1]];
            break;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

//UI------------------------------------------------------------------

- (IBAction)goToSettingsButton:(id)sender {
    SOPIsettingViewController *settingController=[[SOPIsettingViewController alloc ]init];
    [self.navigationController pushViewController: settingController animated:YES];
    [self cancelTouches];
}

- (IBAction)goToTuningButton:(id)sender {
    if(tuningOn){
        [tuningLabel removeFromSuperview];
        [presetLabel removeFromSuperview];

        [self cancelTouches];

        tuningOn=0;
        for(int i=0; i<4; i++){
            ((UIImageView *) [myTunes objectAtIndex: i]).alpha=0.1;
        }
        presetButton.hidden=YES;
        presetSegment.hidden=YES;
        [self savePresets];

    }else{
        [self.view addSubview:tuningLabel];
        [self.view addSubview:presetLabel];

        tuningOn=1;
        switch ([[[NSUserDefaults standardUserDefaults]valueForKey:@"colourDefault"]integerValue]) {
            case 1:
                [self.view setBackgroundColor:[UIColor colorWithRed:0 green:139/255.f blue:0 alpha:1]];
                break;
            case 2:
                [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:139/255.f alpha:1]];
                break;
            default:
                [self.view setBackgroundColor:[UIColor colorWithRed:139/255.f green:0 blue:0 alpha:1]];
                break;
        }
        numberOfCurrentTouches=0;
        for(int i=0; i<4; i++){
            ((UIImageView *) [myTunes objectAtIndex: i]).alpha=1;
        }
        presetButton.hidden=NO;
        presetSegment.hidden=NO;
    }
}

- (IBAction)presetSegment:(id)sender {
    presetNum=presetSegment.selectedSegmentIndex;
    [self doTuning];
}

- (IBAction)presetButton:(id)sender {
    [self savePresets];
}

//TUNING AND PRESETS

- (void)doTuning{
    switch ([[[NSUserDefaults standardUserDefaults]valueForKey:@"colourDefault"]integerValue]) {
        case 0:
            myTune1pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune1x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune1y"]] floatValue]);
            myTune2pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune2x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune2y"]] floatValue]);
            myTune3pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune3x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune3y"]] floatValue]);
            myTune4pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune4x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune4y"]] floatValue]);
            break;
        case 1:
            myTune1pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune1x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune1y"]] floatValue]);
            myTune2pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune2x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune2y"]] floatValue]);
            myTune3pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune3x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune3y"]] floatValue]);
            myTune4pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune4x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune4y"]] floatValue]);
            break;
        case 2:
            myTune1pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune1x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune1y"]] floatValue]);
            myTune2pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune2x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune2y"]] floatValue]);
            myTune3pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune3x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune3y"]] floatValue]);
            myTune4pl= CGPointMake([[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune4x"]] floatValue],
                                   [[dict objectForKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune4y"]] floatValue]);
            break;
        default:
            break;
    }
    tune1.center=myTune1pl;
    tune2.center=myTune2pl;
    tune3.center=myTune3pl;
    tune4.center=myTune4pl;
    lastTune1=tune1.center;
    lastTune2=tune2.center;
    lastTune3=tune3.center;
    lastTune4=tune4.center;
    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 0]).center.x toReceiver:@"tune1x"];
    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 0]).center.y toReceiver:@"tune1y"];
    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 1]).center.x toReceiver:@"tune2x"];
    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 1]).center.y toReceiver:@"tune2y"];
    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 2]).center.x toReceiver:@"tune3x"];
    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 2]).center.y toReceiver:@"tune3y"];
    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 3]).center.x toReceiver:@"tune4x"];
    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 3]).center.y toReceiver:@"tune4y"];

    
//    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 0]).center.x/[UIScreen mainScreen].bounds.size.width toReceiver:@"tune1x"];
//    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 0]).center.y/[UIScreen mainScreen].bounds.size.height toReceiver:@"tune1y"];
 //   [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 1]).center.x/[UIScreen mainScreen].bounds.size.width toReceiver:@"tune2x"];
//    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 1]).center.y/[UIScreen mainScreen].bounds.size.height toReceiver:@"tune2y"];
//    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 2]).center.x/[UIScreen mainScreen].bounds.size.width toReceiver:@"tune3x"];
//    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 2]).center.y/[UIScreen mainScreen].bounds.size.height toReceiver:@"tune3y"];
//    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 3]).center.x/[UIScreen mainScreen].bounds.size.width toReceiver:@"tune4x"];
//    [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 3]).center.y/[UIScreen mainScreen].bounds.size.height toReceiver:@"tune4y"];

    
    
}

- (void)savePresets {
    switch ([[[NSUserDefaults standardUserDefaults]valueForKey:@"colourDefault"]integerValue]) {
        case 0:
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 0]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune1x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 0]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune1y"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 1]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune2x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 1]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune2y"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 2]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune3x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 2]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune3y"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 3]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune4x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 3]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i1tune4y"]];
            break;
        case 1:
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 0]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune1x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 0]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune1y"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 1]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune2x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 1]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune2y"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 2]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune3x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 2]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune3y"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 3]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune4x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 3]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i2tune4y"]];
            break;
        case 2:
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 0]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune1x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 0]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune1y"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 1]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune2x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 1]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune2y"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 2]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune3x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 2]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune3y"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 3]).center.x]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune4x"]];
            [dict setObject:[[NSNumber alloc] initWithInt:((UIImageView *) [myTunes objectAtIndex: 3]).center.y]
                     forKey:[NSString stringWithFormat:@"%@%i%@", @"p", presetNum, @"i3tune4y"]];
            break;
        default:
            break;
    }
    if(![dict writeToFile:path atomically: YES])
        NSLog(@"ERROR");
}

//TOUCH INTERACTION--------------------------------------------------------------------------

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    touchOn=1;
        for (UITouch *touch in touches) {
            touchX=[touch locationInView:self.view].x;
            touchY=[touch locationInView:self.view].y;
            numberOfCurrentTouches++;
        }
    [self checkTouchingTunes];
    if(!touchingTune){
        switch ([[[NSUserDefaults standardUserDefaults]valueForKey:@"colourDefault"]integerValue]) {
            case 1:
                [self.view setBackgroundColor:[UIColor greenColor]];
                break;
            case 2:
                 [self.view setBackgroundColor:[UIColor blueColor]];
                break;
            default:
                [self.view setBackgroundColor:[UIColor redColor]];
                break;
        }
        [self.view addSubview:fingerCircle];
        fingerCircle.center = CGPointMake(touchX,touchY);
        [PdBase sendFloat:touchX toReceiver:@"touchPositionX"];
        [PdBase sendFloat:touchY toReceiver:@"touchPositionY"];
    //    [PdBase sendFloat:touchX/self.view.bounds.size.width toReceiver:@"touchPositionX"];
  //      [PdBase sendFloat:touchY/self.view.bounds.size.height toReceiver:@"touchPositionY"];
        [PdBase sendFloat:1.0 toReceiver:@"screenIsBeingTouched"];
    }
    [super touchesBegan:touches withEvent:event];
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
    touchesMoving=1;
    if(!tuningOn){
        [self checkTouchingTunes];
        for (UITouch *touch in touches) {
            if(!touchingTune){
                fingerCircle.center = CGPointMake([touch locationInView:self.view].x, [touch locationInView:self.view].y);
            }
            touchX=[touch locationInView:self.view].x;
            touchY=[touch locationInView:self.view].y;
        }
        [PdBase sendFloat:touchX toReceiver:@"touchPositionX"];
        [PdBase sendFloat:touchY toReceiver:@"touchPositionY"];
     //   [PdBase sendFloat:touchX/self.view.bounds.size.width toReceiver:@"touchPositionX"];
      //  [PdBase sendFloat:touchY/self.view.bounds.size.height toReceiver:@"touchPositionY"];

        
    }else{
        for (UITouch *touch in touches) {
            CGPoint location = [touch locationInView:self.view];
            CGPoint myLastTunesArray[] = {lastTune1, lastTune2, lastTune3, lastTune4};
            for(int k=0; k<4; k++){
                if(location.x>((UIImageView *) [myTunes objectAtIndex: k]).center.x-40 &&
                   location.x<((UIImageView *) [myTunes objectAtIndex: k]).center.x+40 &&
                   location.y>((UIImageView *) [myTunes objectAtIndex: k]).center.y-40 &&
                   location.y<((UIImageView *) [myTunes objectAtIndex: k]).center.y+40
                   ){
                    ((UIImageView *) [myTunes objectAtIndex: k]).center=location;
                }
            }
            for(int i=0; i<3; i++){
                for(int j=i+1; j<4; j++){
                    if(DistPoints(((UIImageView *) [myTunes objectAtIndex: i]).center,
                                  ((UIImageView *) [myTunes objectAtIndex: j]).center
                                  )<80){
                        ((UIImageView *) [myTunes objectAtIndex: i]).center=myLastTunesArray[i];
                        ((UIImageView *) [myTunes objectAtIndex: j]).center=myLastTunesArray[j];
                    }
                }
            }
            lastTune1 = tune1.center;
            lastTune2 = tune2.center;
            lastTune3 = tune3.center;
            lastTune4 = tune4.center;
        }
    }
}

CGFloat DistPoints(CGPoint point1,CGPoint point2){
    CGFloat dx = point2.x - point1.x;
    CGFloat dy = point2.y - point1.y;
    return sqrt(dx*dx + dy*dy );
};

-(void)checkTouchingTunes{
    if(tuningOn){
        if((touchX>((UIImageView *) [myTunes objectAtIndex: 0]).center.x-40 &&
            touchX<((UIImageView *) [myTunes objectAtIndex: 0]).center.x+40 &&
            touchY>((UIImageView *) [myTunes objectAtIndex: 0]).center.y-40 &&
            touchY<((UIImageView *) [myTunes objectAtIndex: 0]).center.y+40
            )||(touchX>((UIImageView *) [myTunes objectAtIndex: 1]).center.x-40 &&
                touchX<((UIImageView *) [myTunes objectAtIndex: 1]).center.x+40 &&
                touchY>((UIImageView *) [myTunes objectAtIndex: 1]).center.y-40 &&
                touchY<((UIImageView *) [myTunes objectAtIndex: 1]).center.y+40
                )||(touchX>((UIImageView *) [myTunes objectAtIndex: 2]).center.x-40 &&
                    touchX<((UIImageView *) [myTunes objectAtIndex: 2]).center.x+40 &&
                    touchY>((UIImageView *) [myTunes objectAtIndex: 2]).center.y-40 &&
                    touchY<((UIImageView *) [myTunes objectAtIndex: 2]).center.y+40
                    )||(touchX>((UIImageView *) [myTunes objectAtIndex: 3]).center.x-40 &&
                        touchX<((UIImageView *) [myTunes objectAtIndex: 3]).center.x+40 &&
                        touchY>((UIImageView *) [myTunes objectAtIndex: 3]).center.y-40 &&
                        touchY<((UIImageView *) [myTunes objectAtIndex: 3]).center.y+40
                        )){
            touchingTune=1;
        }else{
            touchingTune=0;
        }
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event{
    touchOn=0;
    touchesMoving=0;
    for (UITouch *touch in touches) {
        numberOfCurrentTouches--;
    }
    if (numberOfCurrentTouches==0) {
        switch ([[[NSUserDefaults standardUserDefaults]valueForKey:@"colourDefault"]integerValue]) {
            case 1:
                [self.view setBackgroundColor:[UIColor colorWithRed:0 green:139/255.f blue:0 alpha:1]];
                break;
            case 2:
                [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:139/255.f alpha:1]];
                break;
            default:
                [self.view setBackgroundColor:[UIColor colorWithRed:139/255.f green:0 blue:0 alpha:1]];
                break;
        }

        [fingerCircle removeFromSuperview];
        [PdBase sendFloat:0.0 toReceiver:@"screenIsBeingTouched"];
    }
    [super touchesEnded:touches withEvent:event];
}

- (void) cancelTouches{
    numberOfCurrentTouches=0;
    touchingTune=0;
    if (numberOfCurrentTouches==0) {
        switch ([[[NSUserDefaults standardUserDefaults]valueForKey:@"colourDefault"]integerValue]) {
            case 1:
                [self.view setBackgroundColor:[UIColor colorWithRed:0 green:139/255.f blue:0 alpha:1]];
                break;
            case 2:
                [self.view setBackgroundColor:[UIColor colorWithRed:0 green:0 blue:139/255.f alpha:1]];
                break;
            default:
                [self.view setBackgroundColor:[UIColor colorWithRed:139/255.f green:0 blue:0 alpha:1]];
                break;
        }
        
        [fingerCircle removeFromSuperview];
        [PdBase sendFloat:0.0 toReceiver:@"screenIsBeingTouched"];
    }
}

//VIBRATION------------------------------------------------------------------------------

#pragma mark puredata callbacks
-(void)receiveBangFromSource:(NSString *)source{
    if ([source isEqualToString:@"vibrate"] && [[NSUserDefaults standardUserDefaults]boolForKey:@"vibrationDefault"]) {
        [self vibrate];
    }
}

- (void)vibrate {
    AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

//ACCELEROMETER AND GYROSCOPE-----------------------------------------------------

-(void)accelerometerUpdateAvailable:(CMAccelerometerData*)accelerometerData{
    accelerationX = accelerometerData.acceleration.x * kFilteringFactor + accelerationX * (1.0 - kFilteringFactor);
    accelerationY = accelerometerData.acceleration.y * kFilteringFactor + accelerationY * (1.0 - kFilteringFactor);
    accelerationZ = accelerometerData.acceleration.z * kFilteringFactor + accelerationZ * (1.0 - kFilteringFactor);
}

-(void)gyroscopeUpdateAvailable:(CMGyroData*)gyroscopeData{        
  //  gyroscopeX = gyroscopeData.rotationRate.x * kFilteringFactor + gyroscopeX * (1.0 - kFilteringFactor);
    gyroscopeX = gyroscopeData.rotationRate.x;
    gyroscopeY = gyroscopeData.rotationRate.y;
    gyroscopeZ = gyroscopeData.rotationRate.z;
    }


#pragma mark start/stop motionManager
-(void)startAccelerometerUpdates{
    if ([motionManager isAccelerometerAvailable] && [[NSUserDefaults standardUserDefaults]boolForKey:@"accelerometerDefault"] ) {
        [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            [self accelerometerUpdateAvailable:accelerometerData];
            
        }];
    }
}

-(void)stopAccelerometerUpdates{
    if ([motionManager isAccelerometerActive]) {
        [motionManager stopAccelerometerUpdates];
    }
}

-(void)startGyroscopeUpdates{
    if ([motionManager isGyroAvailable] && [[NSUserDefaults standardUserDefaults]boolForKey:@"gyroscopeDefault"] ) {
        [motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
            [self gyroscopeUpdateAvailable:gyroData];
           
        }];
    }
}

-(void)stopGyroscopeUpdates{
    if ([motionManager isGyroActive]) {
        [motionManager stopGyroUpdates];
    }
}


//NETWORKING-------------------------------------------------------------

- (void)oscConnection:(OSCConnection *)con didReceivePacket:(OSCPacket *)packet fromHost:(NSString *)host port:(UInt16)port{
    if([packet.address isEqualToString:@"/ping"]){
        [self.view addSubview:pingInSquare];
        pingInSquare.alpha=0.5;
        [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(hideSquareIn) userInfo:nil repeats:NO];
    }
}

- (NSString *)getIPAddress {
    NSString *address = @"error";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    // retrieve the current interfaces - returns 0 on success
    success = getifaddrs(&interfaces);
    if (success == 0) {
        // Loop through linked list of interfaces
        temp_addr = interfaces;
        while(temp_addr != NULL) {
            if(temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];                    
                }
            }
            temp_addr = temp_addr->ifa_next;
        }
    }
    // Free memory
    freeifaddrs(interfaces);
    return address;
}

//LOOPS----------------------------------------------------------------

-(void)loopPing{
    NSString *remoteHost = mainHost;
    NSString *remotePort = mainPort;
    NSString *remoteAddress = @"/moping";
    float deviceID=myIP;
    
    OSCMutableMessage *message = [[OSCMutableMessage alloc] init];
    message.address = remoteAddress;
    [message addFloat:deviceID];
    
    [connection sendPacket:message toHost:remoteHost port:[remotePort intValue]];
    //
    [self.view addSubview:pingOutSquare];
    pingOutSquare.alpha=0.5;
    [NSTimer scheduledTimerWithTimeInterval:.5 target:self selector:@selector(hideSquareOut) userInfo:nil repeats:NO];
}

-(void)loopMain{
    NSString *remoteHost = mainHost;
    NSString *remotePort = mainPort;
    float deviceID=myIP;
    NSInteger instrumentID=[[[NSUserDefaults standardUserDefaults]valueForKey:@"colourDefault"] floatValue]+1;
    OSCMutableMessage *message;
    
    //Touch-----------------
    message = [[OSCMutableMessage alloc] init];
    message.address = @"/touch";
    [message addFloat:deviceID];
    [message addFloat:instrumentID];
    [message addFloat:numberOfCurrentTouches];
    [message addFloat:touchX];
    [message addFloat:touchY];
    [connection sendPacket:message toHost:remoteHost port:[remotePort intValue]];
    
    //Accel-----------------
    message = [[OSCMutableMessage alloc] init];
    message.address = @"/acc";
    [message addFloat:deviceID];
    [message addFloat:instrumentID];
    [message addFloat:accelerationX];
    [message addFloat:accelerationY];
    [message addFloat:accelerationZ];
    [connection sendPacket:message toHost:remoteHost port:[remotePort intValue]];
    
    //Gyro-----------------
    message = [[OSCMutableMessage alloc] init];
    message.address = @"/gyro";
    [message addFloat:deviceID];
    [message addFloat:instrumentID];
    [message addFloat:gyroscopeX];
    [message addFloat:gyroscopeY];
    [message addFloat:gyroscopeZ];
    [connection sendPacket:message toHost:remoteHost port:[remotePort intValue]];
    
    //Tuning-----------------
    message = [[OSCMutableMessage alloc] init];
    message.address = @"/tuning";
    [message addFloat:deviceID];
    [message addFloat:instrumentID];
    [message addFloat:((UIImageView *) [myTunes objectAtIndex: 0]).center.x];
    [message addFloat:((UIImageView *) [myTunes objectAtIndex: 0]).center.y];
    [message addFloat:((UIImageView *) [myTunes objectAtIndex: 1]).center.x];
    [message addFloat:((UIImageView *) [myTunes objectAtIndex: 1]).center.y];
    [message addFloat:((UIImageView *) [myTunes objectAtIndex: 2]).center.x];
    [message addFloat:((UIImageView *) [myTunes objectAtIndex: 2]).center.y];
    [message addFloat:((UIImageView *) [myTunes objectAtIndex: 3]).center.x];
    [message addFloat:((UIImageView *) [myTunes objectAtIndex: 3]).center.y];
    [connection sendPacket:message toHost:remoteHost port:[remotePort intValue]];
    
    //LibPD-----------------
    //Touch
    if(touchOn){
        //Accel
        [PdBase sendFloat:accelerationX toReceiver:@"accelerationX"];
        [PdBase sendFloat:accelerationY toReceiver:@"accelerationY"];
        [PdBase sendFloat:accelerationZ toReceiver:@"accelerationZ"];
        //Gyro
        [PdBase sendFloat:gyroscopeX toReceiver:@"gyroscopeX"];
        [PdBase sendFloat:gyroscopeY toReceiver:@"gyroscopeY"];
        [PdBase sendFloat:gyroscopeZ toReceiver:@"gyroscopeZ"];
    
    
        
    }
    if(tuningOn){
        if(touchesMoving&&touchingTune){
            [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 0]).center.x toReceiver:@"tune1x"];
            [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 0]).center.y toReceiver:@"tune1y"];
            [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 1]).center.x toReceiver:@"tune2x"];
            [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 1]).center.y toReceiver:@"tune2y"];
            [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 2]).center.x toReceiver:@"tune3x"];
            [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 2]).center.y toReceiver:@"tune3y"];
            [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 3]).center.x toReceiver:@"tune4x"];
            [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 3]).center.y toReceiver:@"tune4y"];
            
            
      //      [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 0]).center.x/[UIScreen mainScreen].bounds.size.width toReceiver:@"tune1x"];
   //         [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 0]).center.y/[UIScreen mainScreen].bounds.size.height toReceiver:@"tune1y"];
    //        [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 1]).center.x/[UIScreen mainScreen].bounds.size.width toReceiver:@"tune2x"];
   //         [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 1]).center.y/[UIScreen mainScreen].bounds.size.height toReceiver:@"tune2y"];
   //         [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 2]).center.x/[UIScreen mainScreen].bounds.size.width toReceiver:@"tune3x"];
    //        [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 2]).center.y/[UIScreen mainScreen].bounds.size.height toReceiver:@"tune3y"];
    //        [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 3]).center.x/[UIScreen mainScreen].bounds.size.width toReceiver:@"tune4x"];
   //         [PdBase sendFloat:((UIImageView *) [myTunes objectAtIndex: 3]).center.y/[UIScreen mainScreen].bounds.size.height toReceiver:@"tune4y"];
            
        }

            
            
        }
        //Accel
        [PdBase sendFloat:accelerationX toReceiver:@"accelerationX"];
        [PdBase sendFloat:accelerationY toReceiver:@"accelerationY"];
        [PdBase sendFloat:accelerationZ toReceiver:@"accelerationZ"];
        //Gyro
        [PdBase sendFloat:gyroscopeX toReceiver:@"gyroscopeX"];
        [PdBase sendFloat:gyroscopeY toReceiver:@"gyroscopeY"];
        [PdBase sendFloat:gyroscopeZ toReceiver:@"gyroscopeZ"];
        
    

    }

-(void)hideSquareIn{
    [pingInSquare removeFromSuperview];
}

-(void)hideSquareOut{
    [pingOutSquare removeFromSuperview];
}

@end
