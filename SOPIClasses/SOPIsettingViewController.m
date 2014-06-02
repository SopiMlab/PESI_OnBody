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
//  SOPIViewController.m
//  SOPImobile
//


#import "SOPIsettingViewController.h"
#import <AudioToolbox/AudioToolbox.h>
#import "SOPIAppDelegate.h"
#import "SOPIInfoViewController.h"
#import <QuartzCore/QuartzCore.h>

#define kTransitionDuration	0.75
#define kUpdateFrequency 20  // Hz
#define kFilteringFactor 0.05
#define kNoReadingValue 999

@implementation SOPIsettingViewController

CMMotionManager *motionManager;



@synthesize updateRateSlider;
@synthesize updateFrequecyLabel;
@synthesize infoButton;
@synthesize colourSwitch;
@synthesize colourSample;
@synthesize vibrationSwitch;
@synthesize gyroscopeSwitch;
@synthesize gyroscopeBarX,gyroscopeBarY,gyroscopeBarZ;
@synthesize accelerometerSwitch;
@synthesize accelerationBarX,accelerationBarY,accelerationBarZ;
@synthesize IPinfo;


int i,j;

- init {
	if (self = [super init]) {
	}
	return self;
}

//VIEW-------------------------------------------------------------

- (void)viewDidLoad{
    [super viewDidLoad];
    motionManager = [(SOPIAppDelegate *)[[UIApplication sharedApplication] delegate] sharedMotionManager];
    
    
    }








- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return (interfaceOrientation==UIInterfaceOrientationPortrait);
}

-(void)viewWillDisappear:(BOOL)animated{
    [self stopGyroscopeUpdates];
    [self stopAccelerometerUpdates];
}

-(void)viewWillAppear:(BOOL)animated{
    accelerometerSwitch.on=[[NSUserDefaults standardUserDefaults]boolForKey:@"accelerometerDefault"];
    gyroscopeSwitch.on=[[NSUserDefaults standardUserDefaults]boolForKey:@"gyroscopeDefault"];
    vibrationSwitch.on=[[NSUserDefaults standardUserDefaults]boolForKey:@"vibrationDefault"];
    colourSwitch.selectedSegmentIndex=[[[NSUserDefaults standardUserDefaults]valueForKey:@"colourDefault"]integerValue];
    [self changeInfoButtonTint:colourSwitch.selectedSegmentIndex];
    accelerometerSwitch.on?[self startAccelerometerUpdates]:nil;
    gyroscopeSwitch.on?[self startGyroscopeUpdates]:nil;
    [IPinfo setText:[[NSUserDefaults standardUserDefaults]valueForKey:@"ipDefault"]];
    updateRateSlider.value =[[NSUserDefaults standardUserDefaults]floatForKey:@"updateRateDefault"];
    updateFrequecyLabel.text=[NSString stringWithFormat:@"%1.3fs",updateRateSlider.value];
    
    
}




- (void)viewDidUnload{
    [self setAccelerationBarX:nil];
    [self setAccelerometerSwitch:nil];
    [self setGyroscopeSwitch:nil];
    [self setGyroscopeBarX:nil];
    [self setGyroscopeBarY:nil];
    [self setGyroscopeBarZ:nil];
    [self setVibrationSwitch:nil];
    [self setColourSwitch:nil];
    [self setInfoButton:nil];
    [self setColourSample:nil];
    [super viewDidUnload];
    [self setUpdateFrequecyLabel:nil];
    [self setUpdateRateSlider:nil];

    // Release any retained subviews of the main view.
}




//ACCELEROMETER, GYROSCOPE, VIBRATION-------------------------------------------------------------

-(void)accelerometerUpdateAvailable:(CMAccelerometerData*)accelerometerData{        
    accelerationX = accelerometerData.acceleration.x * kFilteringFactor + accelerationX * (1.0 - kFilteringFactor);
    accelerationY = accelerometerData.acceleration.y * kFilteringFactor + accelerationY * (1.0 - kFilteringFactor);
    accelerationZ = accelerometerData.acceleration.z * kFilteringFactor + accelerationZ * (1.0 - kFilteringFactor);
    accelerationBarX.progress=ABS((float)accelerationX);
    accelerationBarY.progress=ABS((float)accelerationY);
    accelerationBarZ.progress=ABS((float)accelerationZ);
    i++;
    if(i%10==0){
     accelerationBarX.progressTintColor=[UIColor colorWithRed:accelerationBarX.progress+0.01 green:0.01 blue:0.01 alpha:accelerationBarX.progress];
    accelerationBarY.progressTintColor=[UIColor colorWithRed:0.1 green:accelerationBarY.progress+0.01 blue:0.01 alpha:accelerationBarY.progress];
    accelerationBarZ.progressTintColor=[UIColor colorWithRed:0.1 green:0.1 blue:accelerationBarZ.progress+0.01 alpha:accelerationBarZ.progress];
    }
}

-(void)gyroscopeUpdateAvailable:(CMGyroData*)gyroscopeData{
    
       // gyroscopeX = gyroscopeData.rotationRate.x* kFilteringFactor + gyroscopeX * (1.0 - kFilteringFactor);;
        gyroscopeX = gyroscopeData.rotationRate.x;
        gyroscopeY = gyroscopeData.rotationRate.y;
        gyroscopeZ = gyroscopeData.rotationRate.z;
    
        gyroscopeBarX.progress=ABS((float)gyroscopeX);
        gyroscopeBarY.progress=ABS((float)gyroscopeY);
        gyroscopeBarZ.progress=ABS((float)gyroscopeZ);
    
    
    
    j++;
    if(j%10==0){
    gyroscopeBarX.progressTintColor=[UIColor colorWithRed:gyroscopeBarX.progress+0.01 green:0.01 blue:0.01 alpha:gyroscopeBarX.progress];
    gyroscopeBarY.progressTintColor=[UIColor colorWithRed:0.1 green:gyroscopeBarY.progress+0.01 blue:0.01 alpha:gyroscopeBarY.progress];
    gyroscopeBarZ.progressTintColor=[UIColor colorWithRed:0.1 green:0.1 blue:gyroscopeBarZ.progress+0.01 alpha:gyroscopeBarZ.progress];
    }
}





#pragma mark start/stop motionManager
-(void)startAccelerometerUpdates{
    if ([motionManager isAccelerometerAvailable]) 
    {
        [motionManager setAccelerometerUpdateInterval:updateRateSlider.value]; // NEW
        [motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMAccelerometerData *accelerometerData, NSError *error) {
            [self accelerometerUpdateAvailable:accelerometerData];
        }];
    }
}

-(void)stopAccelerometerUpdates{
    if ([motionManager isAccelerometerActive]) {
        [motionManager stopAccelerometerUpdates];
    }
    accelerationBarX.progress=0;
    accelerationBarY.progress=0;
    accelerationBarZ.progress=0;

}

-(void)startGyroscopeUpdates{
    if ([motionManager isGyroAvailable]) {
        [motionManager setGyroUpdateInterval:updateRateSlider.value]; // NEW
        [motionManager startGyroUpdatesToQueue:[NSOperationQueue mainQueue] withHandler:^(CMGyroData *gyroData, NSError *error) {
            [self gyroscopeUpdateAvailable:gyroData];
        }];
    }
}

-(void)stopGyroscopeUpdates{
    if ([motionManager isGyroActive]) {
        [motionManager stopGyroUpdates];
    }
    gyroscopeBarX.progress=0;
    gyroscopeBarY.progress=0;
    gyroscopeBarZ.progress=0;

}





// TEST



//UI-----------------------------------------------------------

#pragma mark defaults
- (IBAction)accelerometerSwitch:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:accelerometerSwitch.on forKey:@"accelerometerDefault"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    accelerometerSwitch.on?[self startAccelerometerUpdates]:[self stopAccelerometerUpdates];
}

- (IBAction)gyroscopeSwitch:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:gyroscopeSwitch.on forKey:@"gyroscopeDefault"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    gyroscopeSwitch.on?[self startGyroscopeUpdates]:[self stopGyroscopeUpdates];
}

- (IBAction)vibrationSwitch:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:vibrationSwitch.on forKey:@"vibrationDefault"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)infoButton:(id)sender {
    SOPIInfoViewController  *info=[[SOPIInfoViewController alloc]init];
    [[self navigationController]pushViewController:info animated:YES];
}

- (IBAction)colourSwitch:(id)sender {
    [[NSUserDefaults standardUserDefaults] setInteger:colourSwitch.selectedSegmentIndex forKey:@"colourDefault"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self changeInfoButtonTint:colourSwitch.selectedSegmentIndex];
    [PdBase sendFloat:colourSwitch.selectedSegmentIndex toReceiver:@"instID"];
}

-(void)changeInfoButtonTint:(NSInteger)segIndex{
    switch (segIndex) {
        case 0:
            colourSample.backgroundColor=[UIColor redColor];
            break;
        case 1:
            colourSample.backgroundColor=[UIColor greenColor];
            break;
        case 2:
            colourSample.backgroundColor=[UIColor blueColor];
            break;
        default:
            colourSample.backgroundColor=[UIColor grayColor];
            break;
    }
}




//VIEW EXIT---------------------------------------------------------

#pragma mark view navigation
- (IBAction)done:(id)sender {
    [[self navigationController] popToRootViewControllerAnimated:YES];
}

- (IBAction)updateRate:(id)sender {
    
    updateFrequecyLabel.text=[NSString stringWithFormat:@"%1.3fs",updateRateSlider.value];
    
   [motionManager setGyroUpdateInterval:updateRateSlider.value];
    [motionManager setAccelerometerUpdateInterval:updateRateSlider.value];
    [motionManager  setDeviceMotionUpdateInterval:updateRateSlider.value]; //NEW
    
    [[NSUserDefaults standardUserDefaults] setFloat:updateRateSlider.value forKey:@"updateRateDefault"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
}


//-----------------





@end
