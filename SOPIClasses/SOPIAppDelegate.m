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
//  SOPIAppDelegate.m
//  SOPImobile
//


#import "SOPIAppDelegate.h"

@interface SOPIAppDelegate(){
    CMMotionManager *motionManager;
    CMAttitude *referenceAttitude;
}
@property (strong, nonatomic) UINavigationController* navigationController;
@property (strong, nonatomic) SOPIsettingViewController *settingController;
@property (retain, nonatomic) SOPIperformanceViewController *performanceController;
@property (strong,nonatomic,readonly) PdAudioController* audioController;
@end

@implementation SOPIAppDelegate

@synthesize window = _window;
@synthesize settingController = _settingController;
@synthesize performanceController = _performanceController;
@synthesize audioController =_audioController;
@synthesize navigationController=_navigationController;
@synthesize sharedMotionManager=_sharedMotionManager;


- (CMMotionManager *)sharedMotionManager
{
    if (!motionManager){
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            motionManager = [[CMMotionManager alloc] init];
            motionManager.showsDeviceMovementDisplay = YES;
            NSLog(@"---------- creating CMMotionManager");
            
        });
   
    }
    return motionManager;
}








//APP DEFAULTS----------------------------------
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:1] forKey:@"accelerometerDefault"]];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:1] forKey:@"gyroscopeDefault"]];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:1] forKey:@"vibrationDefault"]];
        
    [[NSUserDefaults standardUserDefaults] registerDefaults:
     [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:0] forKey:@"colourDefault"]];
    
    [[NSUserDefaults standardUserDefaults] registerDefaults:
    [NSDictionary dictionaryWithObject:@"." forKey:@"ipDefault"]];

    
    //MICROPHONE OFF - it disables the audio input and activates the vibration output --------
    
    _audioController=[[PdAudioController alloc]init];
    if ([self.audioController configureAmbientWithSampleRate:44100 numberChannels:2  mixingEnabled:YES]!=PdAudioOK) {
        NSLog(@"failed to launch pd audio controller.");
    }
   
    //MICROPHONE ON - it enables the audio input and disables the vibration output ---------

    
    //_audioController=[[PdAudioController alloc]init];
    //if ([self.audioController configurePlaybackWithSampleRate:44100 numberChannels:2 ////inputEnabled:YES mixingEnabled:YES]!=PdAudioOK) {
    //NSLog(@"failed to launch pd audio controller.");
    //}
    
    
    [self.audioController setActive:YES];
	
    //AUDIO CONFIGURATION----------------------------------
    [self.audioController configurePlaybackWithSampleRate:44100 numberChannels:2 inputEnabled:NO mixingEnabled:NO];
    [self.audioController configureTicksPerBuffer:64];
    [self.audioController setActive:YES];
    [self.audioController print];
    
    _settingController = [[SOPIsettingViewController alloc] initWithNibName:@"SOPIsettingViewController" bundle:nil];
    _performanceController=[[SOPIperformanceViewController alloc]initWithNibName:@"SOPIperformanceViewController" bundle:nil];
    _navigationController=[[UINavigationController alloc]init];
    
    NSArray *viewControllers=[NSArray arrayWithObjects:self.performanceController,self.settingController, nil];
    
    [self.navigationController setNavigationBarHidden:YES];
    [self.navigationController setViewControllers:viewControllers];
    [self.navigationController popToRootViewControllerAnimated:NO];
    self.navigationController.delegate=self;
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.rootViewController = self.navigationController;
    [self.window addSubview:self.performanceController.view];
    [self.window makeKeyAndVisible];
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application{
    self.audioController.active=YES;
    NSLog(@"starting PD audio controller");
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

@end
